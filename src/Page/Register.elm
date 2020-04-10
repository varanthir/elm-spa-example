module Page.Register exposing (Model, Msg, init, pageTitle, subscriptions, update, view)

import Api
import Browser.Navigation as Nav
import Credentials exposing (httpRegisterAndLogin)
import Html exposing (Html, button, div, form, h1, input, label, text)
import Html.Attributes exposing (autocomplete, class, disabled, name, style, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Session exposing (Session)
import Styled
import Task



-- MODEL


type alias Form =
    { username : String
    , password : String
    , passwordRepeat : String
    }


type Status
    = NotStarted
    | Pending
    | Failed Http.Error


type alias SubModel =
    { navKey : Nav.Key
    , form : Form
    , status : Status
    }


type Model
    = Model SubModel


init : Nav.Key -> Model
init navKey =
    Model
        { navKey = navKey
        , form = Form "" "" ""
        , status = NotStarted
        }



-- UPDATE


type Msg
    = UpdateUsername String
    | UpdatePassword String
    | UpdatePasswordRepeat String
    | Register
    | RegisterSuccess Session
    | RegisterError Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model subModel) =
    case msg of
        UpdateUsername username ->
            ( updateUsername subModel username
            , Cmd.none
            )

        UpdatePassword password ->
            ( updatePassword subModel password
            , Cmd.none
            )

        UpdatePasswordRepeat passwordRepeat ->
            ( updatePasswordRepeat subModel passwordRepeat
            , Cmd.none
            )

        Register ->
            ( Model { subModel | status = Pending }
            , Task.attempt toRegisterMsg <|
                httpRegisterAndLogin (Credentials.toCredentials subModel.form)
            )

        RegisterSuccess session ->
            ( Model subModel
            , Session.storeCmd (Just session)
            )

        RegisterError error ->
            ( Model { subModel | status = Failed error }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    Sub.none



-- VIEW


pageTitle : String
pageTitle =
    "Register"


view : Model -> List (Html Msg)
view (Model subModel) =
    [ h1 [] [ text "Register" ]
    , viewForm subModel
    ]
        ++ viewStatus subModel.status


viewForm : SubModel -> Html Msg
viewForm subModel =
    let
        { username, password, passwordRepeat } =
            subModel.form
    in
    form
        [ class "frame", onSubmit Register ]
        [ viewInput UpdateUsername "Username: " "text" "new-username" username
        , viewInput UpdatePassword "Password: " "password" "new-password" password
        , viewInput UpdatePasswordRepeat "Password repeat: " "password" "new-password-repeat" passwordRepeat
        , viewSubmitButton subModel
        ]


viewInput : (String -> Msg) -> String -> String -> String -> String -> Html Msg
viewInput updateMsg labelText inputType inputName inputValue =
    div
        [ class "frame" ]
        [ label
            [ style "display" "inline-block" ]
            [ div [] [ text labelText ]
            , input
                [ type_ inputType
                , autocomplete True
                , onInput updateMsg
                , name inputName
                , value inputValue
                ]
                []
            ]
        ]


viewSubmitButton : SubModel -> Html Msg
viewSubmitButton { form, status } =
    let
        isDisabled =
            isFormInvalid form || status == Pending
    in
    Styled.frame
        [ button
            [ type_ "submit", disabled isDisabled ]
            [ text "Register" ]
        ]


viewStatus : Status -> List (Html Msg)
viewStatus status =
    case status of
        Failed error ->
            [ Styled.niceFrame [ text ("Registering has failed: " ++ Api.httpErrorToString error) ] ]

        _ ->
            []



-- HELPERS


toRegisterMsg : Result Http.Error Session -> Msg
toRegisterMsg result =
    case result of
        Ok session ->
            RegisterSuccess session

        Err error ->
            RegisterError error


updateUsername : SubModel -> String -> Model
updateUsername subModel newUsername =
    let
        form =
            subModel.form
    in
    Model { subModel | form = { form | username = newUsername } }


updatePassword : SubModel -> String -> Model
updatePassword subModel newPassword =
    let
        form =
            subModel.form
    in
    Model { subModel | form = { form | password = newPassword } }


updatePasswordRepeat : SubModel -> String -> Model
updatePasswordRepeat subModel newPasswordRepeat =
    let
        form =
            subModel.form
    in
    Model { subModel | form = { form | passwordRepeat = newPasswordRepeat } }


isFormInvalid : Form -> Bool
isFormInvalid { username, password, passwordRepeat } =
    username == "" || password == "" || passwordRepeat == "" || password /= passwordRepeat
