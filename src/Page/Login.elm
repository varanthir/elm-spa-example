module Page.Login exposing (Model, Msg, init, pageTitle, update, view)

import Browser.Navigation as Nav
import Credentials exposing (httpLogin)
import Html exposing (Html, button, div, h1, input, label, text)
import Html.Attributes exposing (autocomplete, class, disabled, name, style, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Session exposing (Session)
import Styled



-- MODEL


type alias Form =
    { username : String
    , password : String
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
        , form = Form "" ""
        , status = NotStarted
        }



-- UPDATE


type Msg
    = UpdateUsername String
    | UpdatePassword String
    | Login
    | LoginSuccess Session
    | LoginError Http.Error


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

        Login ->
            ( Model { subModel | status = Pending }
            , httpLogin toLoginMsg <|
                Credentials.toCredentials subModel.form
            )

        LoginSuccess session ->
            ( Model subModel
            , Session.storeCmd (Just session)
            )

        LoginError error ->
            ( Model { subModel | status = Failed error }
            , Cmd.none
            )



-- VIEW


pageTitle : String
pageTitle =
    "Login"


view : Model -> List (Html Msg)
view (Model subModel) =
    [ h1 [] [ text "Login" ]
    , viewForm subModel
    ]
        ++ viewStatus subModel.status


viewForm : SubModel -> Html Msg
viewForm { form, status } =
    let
        isDisabled =
            isFormInvalid form || status == Pending
    in
    Html.form
        [ class "frame"
        , onSubmit Login
        ]
        [ viewInput UpdateUsername "Username: " "text" "username" form.username
        , viewInput UpdatePassword "Password: " "password" "current-password" form.password
        , viewSubmitButton isDisabled
        ]


viewInput : (String -> Msg) -> String -> String -> String -> String -> Html Msg
viewInput toUpdateMsg labelText inputType inputName inputValue =
    div
        [ class "frame" ]
        [ label
            [ style "display" "inline-block" ]
            [ div [] [ text labelText ]
            , input
                [ type_ inputType
                , autocomplete True
                , onInput toUpdateMsg
                , name inputName
                , value inputValue
                ]
                []
            ]
        ]


viewSubmitButton : Bool -> Html Msg
viewSubmitButton isDisabled =
    Styled.frame
        [ button
            [ type_ "submit", disabled isDisabled ]
            [ text "Login" ]
        ]


viewStatus : Status -> List (Html Msg)
viewStatus status =
    case status of
        Failed error ->
            [ Styled.niceFrame [ text ("Failed: " ++ viewErrorStatus error) ] ]

        _ ->
            []


viewErrorStatus : Http.Error -> String
viewErrorStatus error =
    if error == Http.BadStatus 401 then
        "Login and password do not match."

    else
        "Something went wrong, try again."



-- HELPERS


toLoginMsg : Result Http.Error Session -> Msg
toLoginMsg result =
    case result of
        Ok session ->
            LoginSuccess session

        Err error ->
            LoginError error


updateUsername : SubModel -> String -> Model
updateUsername subModel username =
    let
        { form } =
            subModel
    in
    Model { subModel | form = { form | username = username } }


updatePassword : SubModel -> String -> Model
updatePassword subModel password =
    let
        { form } =
            subModel
    in
    Model { subModel | form = { form | password = password } }


isFormInvalid : Form -> Bool
isFormInvalid { username, password } =
    username == "" || password == ""
