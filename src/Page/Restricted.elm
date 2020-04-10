module Page.Restricted exposing
    ( Model
    , Msg
    , fromRoute
    , update
    , updateSession
    , view
    )

import Browser.Navigation as Nav
import Html exposing (Html)
import Page.PostCreate as PostCreate
import Page.PostEdit as PostEdit
import Page.PostView as PostView
import Page.Posts as Posts
import Page.Settings as Settings
import Route.Restricted as Route exposing (Route)
import Session exposing (Session)



-- MODEL


type Model
    = Posts Posts.Model
    | PostCreate PostCreate.Model
    | PostEdit PostEdit.Model
    | PostView PostView.Model
    | Settings Settings.Model


type Msg
    = PostsMsg Posts.Msg
    | PostCreateMsg PostCreate.Msg
    | PostEditMsg PostEdit.Msg
    | PostViewMsg PostView.Msg
    | SettingsMsg Settings.Msg



-- VIEW


view : Model -> ( String, List (Html Msg) )
view model =
    case model of
        Posts postsModel ->
            ( Posts.pageTitle
            , List.map (Html.map PostsMsg) <| Posts.view postsModel
            )

        PostCreate postCreateModel ->
            ( PostCreate.pageTitle
            , List.map (Html.map PostCreateMsg) <| PostCreate.view postCreateModel
            )

        PostEdit postEditModel ->
            ( PostEdit.pageTitle
            , List.map (Html.map PostEditMsg) <| PostEdit.view postEditModel
            )

        PostView postViewModel ->
            ( PostView.pageTitle
            , List.map (Html.map PostViewMsg) <| PostView.view postViewModel
            )

        Settings settingsModel ->
            ( Settings.pageTitle
            , List.map (Html.map SettingsMsg) <| Settings.view settingsModel
            )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( PostsMsg postsMsg, Posts postsModel ) ->
            Tuple.mapBoth Posts (Cmd.map PostsMsg) <|
                Posts.update postsMsg postsModel

        ( PostCreateMsg postCreateMsg, PostCreate postCreateModel ) ->
            Tuple.mapBoth PostCreate (Cmd.map PostCreateMsg) <|
                PostCreate.update postCreateMsg postCreateModel

        ( PostEditMsg postEditMsg, PostEdit postEditModel ) ->
            Tuple.mapBoth PostEdit (Cmd.map PostEditMsg) <|
                PostEdit.update postEditMsg postEditModel

        ( PostViewMsg postViewMsg, PostView postViewModel ) ->
            Tuple.mapBoth PostView (Cmd.map PostViewMsg) <|
                PostView.update postViewMsg postViewModel

        ( SettingsMsg settingsMsg, Settings settingsModel ) ->
            Tuple.mapBoth Settings (Cmd.map SettingsMsg) <|
                Settings.update settingsMsg settingsModel

        _ ->
            ( model, Cmd.none )


updateSession : Session -> Model -> Model
updateSession newSession model =
    case model of
        Posts postsModel ->
            Posts <|
                Posts.updateSession newSession postsModel

        PostCreate postCreateModel ->
            PostCreate <|
                PostCreate.updateSession newSession postCreateModel

        PostEdit postEditModel ->
            PostEdit <|
                PostEdit.updateSession newSession postEditModel

        PostView postViewModel ->
            PostView <|
                PostView.updateSession newSession postViewModel

        Settings settingsModel ->
            Settings <|
                Settings.updateSession newSession settingsModel



-- HELPERS


fromRoute : Nav.Key -> Session -> Route -> ( Model, Cmd Msg )
fromRoute navKey session route =
    case route of
        Route.Posts ->
            ( Posts <| Posts.initModel session
            , Cmd.map PostsMsg <| Posts.initCmd session
            )

        Route.PostCreate ->
            ( PostCreate <| PostCreate.initModel session navKey
            , Cmd.map PostCreateMsg <| PostCreate.initCmd
            )

        Route.PostEdit postId ->
            ( PostEdit <| PostEdit.initModel session navKey postId
            , Cmd.map PostEditMsg <| PostEdit.initCmd session postId
            )

        Route.PostView postId ->
            ( PostView <| PostView.initModel session navKey postId
            , Cmd.map PostViewMsg <| PostView.initCmd session postId
            )

        Route.Settings ->
            ( Settings <| Settings.initModel session
            , Cmd.map SettingsMsg <| Settings.initCmd session
            )
