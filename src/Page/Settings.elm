module Page.Settings exposing
    ( Model
    , Msg
    , initCmd
    , initModel
    , pageTitle
    , update
    , updateSession
    , view
    )

import Api
import Browser.Dom as Dom
import Credentials exposing (httpUpdateCredentialsTask, toUpdateCredentialsData)
import Html exposing (Html, button, div, form, h1, h2, input, label, p, text)
import Html.Attributes exposing (autocomplete, class, disabled, id, name, style, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Session exposing (Session)
import Task
import User exposing (User)


type alias Form =
    { password : String
    , newPassword : String
    , newPasswordRepeat : String
    }


type UserStatus
    = UserPending
    | UserSuccess User
    | UserFailed Http.Error


type Status
    = NotStarted
    | Pending
    | Success
    | Failed Http.Error


type alias SubModel =
    { session : Session
    , form : Form
    , status : Status
    , userStatus : UserStatus
    }


type Model
    = Model SubModel


initModel : Session -> Model
initModel session =
    Model
        { session = session
        , form = Form "" "" ""
        , status = NotStarted
        , userStatus = UserPending
        }


initCmd : Session -> Cmd Msg
initCmd session =
    Cmd.batch
        [ focusPasswordInput
        , Task.attempt toGetUserMsg <|
            User.httpGetUserTask session
        ]


type Msg
    = NoOp
    | GetUserSuccess ( User, Cmd Msg )
    | GetUserFailure Http.Error
    | UpdatePassword String
    | UpdateNewPassword String
    | UpdateNewPasswordRepeat String
    | UpdateCredentials
    | UpdateCredentialsSuccess ( (), Cmd Msg )
    | UpdateCredentialsFailure Http.Error
    | Logout


update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model subModel) =
    case msg of
        NoOp ->
            ( Model subModel, Cmd.none )

        GetUserSuccess ( user, cmd ) ->
            ( Model { subModel | userStatus = UserSuccess user }
            , cmd
            )

        GetUserFailure error ->
            ( Model { subModel | userStatus = UserFailed error }
            , Cmd.none
            )

        UpdatePassword password ->
            ( updatePassword subModel password
            , Cmd.none
            )

        UpdateNewPassword newPassword ->
            ( updateNewPassword subModel newPassword
            , Cmd.none
            )

        UpdateNewPasswordRepeat newPasswordRepeat ->
            ( updateNewPasswordRepeat subModel newPasswordRepeat
            , Cmd.none
            )

        UpdateCredentials ->
            ( Model { subModel | status = Pending }
            , Task.attempt toUpdateCredentialsMsg <|
                httpUpdateCredentialsTask subModel.session (toUpdateCredentialsData subModel.form)
            )

        UpdateCredentialsSuccess ( (), cmd ) ->
            ( Model { subModel | status = Success, form = Form "" "" "" }
            , cmd
            )

        UpdateCredentialsFailure error ->
            ( Model { subModel | status = Failed error }
            , Cmd.none
            )

        Logout ->
            ( Model subModel
            , Session.storeCmd Nothing
            )


updateSession : Session -> Model -> Model
updateSession newSession (Model subModel) =
    Model { subModel | session = newSession }


pageTitle : String
pageTitle =
    "Settings"


view : Model -> List (Html Msg)
view (Model { form, status, userStatus }) =
    let
        isButtonDisabled =
            isFormInvalid form || status == Pending
    in
    [ h1 [] [ text "Settings" ]
    , h2 [] [ text "Username" ]
    , p [] [ text (toUsername userStatus) ]
    , h2 [] [ text "New Password" ]
    , viewForm isButtonDisabled form
    ]
        ++ viewStatus status


toUsername : UserStatus -> String
toUsername userStatus =
    case userStatus of
        UserPending ->
            "Loading..."

        UserSuccess { username } ->
            username

        UserFailed error ->
            Api.httpErrorToString error


viewForm : Bool -> Form -> Html Msg
viewForm isPending { password, newPassword, newPasswordRepeat } =
    form
        [ class "frame", onSubmit UpdateCredentials ]
        [ viewPasswordInput password
        , viewNewPasswordInput newPassword
        , viewNewPasswordRepeatInput newPasswordRepeat
        , button [ type_ "submit", disabled isPending ] [ text "Update password" ]
        ]


viewPasswordInput : String -> Html Msg
viewPasswordInput password =
    viewInput UpdatePassword [ id currentPasswordId ] "Password:" "current-password" password


viewNewPasswordInput : String -> Html Msg
viewNewPasswordInput newPassword =
    viewInput UpdateNewPassword [] "New password:" "new-password" newPassword


viewNewPasswordRepeatInput : String -> Html Msg
viewNewPasswordRepeatInput newPasswordRepeat =
    viewInput UpdateNewPasswordRepeat [] "Repeat new password:" "new-password-repeat" newPasswordRepeat


viewInput : (String -> Msg) -> List (Html.Attribute Msg) -> String -> String -> String -> Html Msg
viewInput msg extraAttributes labelText inputName inputValue =
    let
        attributes =
            [ autocomplete True
            , name inputName
            , onInput msg
            , type_ "password"
            , value inputValue
            ]
                ++ extraAttributes
    in
    div
        [ class "frame" ]
        [ label
            [ style "display" "inline-block" ]
            [ div [] [ text labelText ]
            , input attributes []
            ]
        ]


viewStatus : Status -> List (Html Msg)
viewStatus status =
    case status of
        Success ->
            [ div [ class "frame" ] [ text "Password updated!" ] ]

        Failed error ->
            [ div [ class "frame" ] [ text ("Updating password failed: " ++ Api.httpErrorToString error) ] ]

        _ ->
            []



-- HELPERS


toMsg : (( a, Cmd Msg ) -> Msg) -> (Http.Error -> Msg) -> Result Http.Error ( a, Cmd Msg, Session ) -> Msg
toMsg successMsg failureMsg result =
    Api.toMsg successMsg failureMsg Logout result


toUpdateCredentialsMsg : Result Http.Error ( (), Cmd Msg, Session ) -> Msg
toUpdateCredentialsMsg result =
    toMsg UpdateCredentialsSuccess UpdateCredentialsFailure result


toGetUserMsg : Result Http.Error ( User, Cmd Msg, Session ) -> Msg
toGetUserMsg result =
    toMsg GetUserSuccess GetUserFailure result


isFormInvalid : Form -> Bool
isFormInvalid { password, newPassword, newPasswordRepeat } =
    password == "" || newPassword == "" || newPasswordRepeat == "" || newPassword /= newPasswordRepeat


currentPasswordId : String
currentPasswordId =
    "current-password"


focusPasswordInput : Cmd Msg
focusPasswordInput =
    Task.attempt (\_ -> NoOp) (Dom.focus currentPasswordId)


updatePassword : SubModel -> String -> Model
updatePassword subModel password =
    let
        { form } =
            subModel
    in
    Model { subModel | form = { form | password = password } }


updateNewPassword : SubModel -> String -> Model
updateNewPassword subModel newPassword =
    let
        { form } =
            subModel
    in
    Model { subModel | form = { form | newPassword = newPassword } }


updateNewPasswordRepeat : SubModel -> String -> Model
updateNewPasswordRepeat subModel newPasswordRepeat =
    let
        { form } =
            subModel
    in
    Model { subModel | form = { form | newPasswordRepeat = newPasswordRepeat } }
