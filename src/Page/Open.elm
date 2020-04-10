module Page.Open exposing
    ( Model
    , Msg
    , fromRoute
    , update
    , view
    )

import Browser.Navigation as Nav
import Html exposing (Html)
import Page.Login as Login
import Page.Register as Register
import Route.Open as Route exposing (Route)



-- MODEL


type Model
    = Login Login.Model
    | Register Register.Model


type Msg
    = LoginMsg Login.Msg
    | RegisterMsg Register.Msg



-- VIEW


view : Model -> ( String, List (Html Msg) )
view model =
    case model of
        Login loginModel ->
            ( Login.pageTitle
            , List.map (Html.map LoginMsg) <| Login.view loginModel
            )

        Register registerModel ->
            ( Register.pageTitle
            , List.map (Html.map RegisterMsg) <| Register.view registerModel
            )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( LoginMsg loginMsg, Login loginModel ) ->
            Tuple.mapBoth Login (Cmd.map LoginMsg) <|
                Login.update loginMsg loginModel

        ( RegisterMsg registerMsg, Register registerModel ) ->
            Tuple.mapBoth Register (Cmd.map RegisterMsg) <|
                Register.update registerMsg registerModel

        _ ->
            ( model, Cmd.none )



-- HELPERS


fromRoute : Nav.Key -> Route -> Model
fromRoute navKey route =
    case route of
        Route.Login ->
            Login <| Login.init navKey

        Route.Register ->
            Register <| Register.init navKey
