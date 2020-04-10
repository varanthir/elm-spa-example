module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Credentials
import Header
import Html exposing (Html, a, footer, h1, main_, text)
import Html.Attributes exposing (class, href)
import Json.Decode as Decode
import Page.Open
import Page.Restricted
import Route exposing (Route)
import Route.Open
import Session exposing (Session)
import Url



-- MAIN


main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChange
        , onUrlRequest = UrlRequest
        }



-- MODEL


type Page
    = Redirect
    | NotFound
    | Open Page.Open.Model
    | Restricted Page.Restricted.Model


type alias Model =
    { navKey : Nav.Key
    , url : Url.Url
    , session : Maybe Session
    , page : Page
    }


init : Decode.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        maybeSession =
            Session.decode flags

        maybeRoute =
            Route.fromUrl url

        ( page, cmd ) =
            redirectOnUrlChange navKey Redirect maybeSession maybeRoute
    in
    ( Model navKey url maybeSession page
    , cmd
    )


type Msg
    = NoOp
    | UrlChange Url.Url
    | UrlRequest Browser.UrlRequest
    | SessionUpdate Session
    | Loggedin Session
    | Loggedout
    | Logout Session
    | OpenMsg Page.Open.Msg
    | RestrictedMsg Page.Restricted.Msg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( UrlChange newUrl, _ ) ->
            urlChangeUpdate model newUrl

        ( UrlRequest (Browser.Internal newUrl), _ ) ->
            urlRequestUpdate model newUrl

        ( UrlRequest (Browser.External href), _ ) ->
            ( model
            , Nav.load href
            )

        ( SessionUpdate newSession, Restricted restrictedModel ) ->
            ( { model
                | session = Just newSession
                , page = Restricted <| Page.Restricted.updateSession newSession restrictedModel
              }
            , Cmd.none
            )

        ( Loggedin newSession, _ ) ->
            ( { model | session = Just newSession }
            , Nav.replaceUrl model.navKey (Route.toString Route.defaultRestricted)
            )

        ( Loggedout, _ ) ->
            ( { model | session = Nothing }
            , Nav.replaceUrl model.navKey (Route.toString Route.defaultOpen)
            )

        ( Logout session, _ ) ->
            ( model
            , Cmd.batch
                [ Credentials.httpLogout (\_ -> NoOp) session
                , Session.storeCmd Nothing
                ]
            )

        ( OpenMsg openMsg, Open openModel ) ->
            updateOpenPage model openModel openMsg

        ( RestrictedMsg restrictedMsg, Restricted restrictedModel ) ->
            updateRestrictedPage model restrictedModel restrictedMsg

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions { session } =
    Session.changes (toSessionMsg session)



-- VIEW


view : Model -> Browser.Document Msg
view { page, session } =
    let
        ( title, content ) =
            case page of
                Redirect ->
                    ( "Redirect"
                    , [ text "Redirecting..." ]
                    )

                NotFound ->
                    ( "Not Found"
                    , [ h1 [] [ text "Not Found" ] ]
                    )

                Open openPage ->
                    Tuple.mapSecond (List.map (Html.map OpenMsg)) <|
                        Page.Open.view openPage

                Restricted restrictedPage ->
                    Tuple.mapSecond (List.map (Html.map RestrictedMsg)) <|
                        Page.Restricted.view restrictedPage
    in
    { title = "Test App - " ++ title
    , body =
        [ Header.view Logout session
        , viewMain content
        , viewFooter
        ]
    }


viewMain : List (Html Msg) -> Html Msg
viewMain content =
    main_ [ class "nice-frame" ] content


viewFooter : Html msg
viewFooter =
    footer
        [ class "nice-frame" ]
        [ a
            [ class "invisible-link", href "/not-found" ]
            [ text "©" ]
        , text " 2020 Kopirajt"
        ]



-- HELPERS


toSessionMsg : Maybe Session -> Maybe Session -> Msg
toSessionMsg maybeCurrSession maybeNewSession =
    case ( maybeCurrSession, maybeNewSession ) of
        ( _, Nothing ) ->
            Loggedout

        ( Nothing, Just newSession ) ->
            Loggedin newSession

        ( Just currSession, Just newSession ) ->
            if Session.toRefreshToken currSession == Session.toRefreshToken newSession then
                SessionUpdate newSession

            else
                Loggedin newSession


redirectOnUrlChange :
    Nav.Key
    -> Page
    -> Maybe Session
    -> Maybe Route
    -> ( Page, Cmd Msg )
redirectOnUrlChange navKey currPage maybeSession maybeRoute =
    case ( maybeSession, maybeRoute ) of
        -- No session, no route -> redirect to Login
        ( Nothing, Nothing ) ->
            ( currPage
            , Nav.replaceUrl navKey (Route.Open.toString Route.Open.Login)
            )

        -- Has session, no route -> NotFound page
        ( Just _, Nothing ) ->
            ( NotFound
            , Cmd.none
            )

        -- No session, restricted route -> redirect to (Open) Login
        ( Nothing, Just (Route.Restricted _) ) ->
            ( currPage
            , Nav.replaceUrl navKey (Route.toString Route.defaultOpen)
            )

        -- Has session, open route -> redirect to (Restricted) Posts
        ( Just _, Just (Route.Open _) ) ->
            ( currPage
            , Nav.replaceUrl navKey (Route.toString Route.defaultRestricted)
            )

        -- No session, open route -> Open page
        ( Nothing, Just (Route.Open openRoute) ) ->
            ( Open <| Page.Open.fromRoute navKey openRoute
            , Cmd.none
            )

        -- Has session, restricted route -> Restricted page
        ( Just session, Just (Route.Restricted restrictedRoute) ) ->
            Tuple.mapBoth Restricted (Cmd.map RestrictedMsg) <|
                Page.Restricted.fromRoute navKey session restrictedRoute


urlChangeUpdate : Model -> Url.Url -> ( Model, Cmd Msg )
urlChangeUpdate model newUrl =
    let
        { navKey, session, page } =
            model

        maybeRoute =
            Route.fromUrl newUrl

        ( newPage, cmd ) =
            redirectOnUrlChange navKey page session maybeRoute
    in
    ( { model | url = newUrl, page = newPage }
    , cmd
    )


urlRequestUpdate : Model -> Url.Url -> ( Model, Cmd Msg )
urlRequestUpdate model newUrl =
    if newUrl == model.url then
        ( model, Cmd.none )

    else
        ( model
        , Nav.pushUrl model.navKey <| Url.toString newUrl
        )


updateOpenPage : Model -> Page.Open.Model -> Page.Open.Msg -> ( Model, Cmd Msg )
updateOpenPage model openModel openMsg =
    let
        ( newOpenModel, openCmd ) =
            Page.Open.update openMsg openModel
    in
    ( { model | page = Open newOpenModel }
    , Cmd.map OpenMsg openCmd
    )


updateRestrictedPage : Model -> Page.Restricted.Model -> Page.Restricted.Msg -> ( Model, Cmd Msg )
updateRestrictedPage model restrictedModel restrictedMsg =
    let
        ( newRestrictedModel, restrictedCmd ) =
            Page.Restricted.update restrictedMsg restrictedModel
    in
    ( { model | page = Restricted newRestrictedModel }
    , Cmd.map RestrictedMsg restrictedCmd
    )
