module Page.PostCreate exposing
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
import Browser.Navigation as Nav
import Html exposing (Html, button, div, h1, input, label, text, textarea)
import Html.Attributes exposing (class, disabled, id, style, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Post exposing (Post)
import Route.Restricted
import Session exposing (Session)
import Styled
import Task



-- MODEL


type alias Form =
    { title : String
    , content : String
    }


type PostStatus
    = NotStarted
    | Pending
    | Success Post
    | Failed Http.Error


type alias SubModel =
    { session : Session
    , navKey : Nav.Key
    , form : Form
    , postStatus : PostStatus
    }


type Model
    = Model SubModel


initModel : Session -> Nav.Key -> Model
initModel session navKey =
    Model
        { session = session
        , navKey = navKey
        , form = Form "" ""
        , postStatus = NotStarted
        }


initCmd : Cmd Msg
initCmd =
    focusTitleInput


type Msg
    = NoOp
    | UpdateTitle String
    | UpdateContent String
    | CreatePost
    | CreatePostSuccess ( Post, Cmd Msg )
    | CreatePostFailure Http.Error
    | Logout



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model subModel) =
    case msg of
        NoOp ->
            ( Model subModel, Cmd.none )

        UpdateTitle newTitle ->
            ( updateTitle subModel newTitle
            , Cmd.none
            )

        UpdateContent newContent ->
            ( updateContent subModel newContent
            , Cmd.none
            )

        CreatePost ->
            ( Model { subModel | postStatus = Pending }
            , Task.attempt toCreatePostMsg <|
                Post.httpCreatePostTask subModel.session (Post.toPostData subModel.form)
            )

        CreatePostSuccess ( post, cmd ) ->
            ( Model { subModel | postStatus = Success post }
            , Cmd.batch
                [ cmd
                , navigateToPost subModel.navKey post.id
                ]
            )

        CreatePostFailure error ->
            ( Model { subModel | postStatus = Failed error }
            , Cmd.none
            )

        Logout ->
            ( Model subModel
            , Session.storeCmd Nothing
            )


navigateToPost : Nav.Key -> Int -> Cmd msg
navigateToPost navKey postId =
    Nav.replaceUrl navKey <|
        Route.Restricted.toString (Route.Restricted.PostView postId)


updateSession : Session -> Model -> Model
updateSession newSession (Model subModel) =
    Model { subModel | session = newSession }



-- VIEW


pageTitle : String
pageTitle =
    "Create Post"


view : Model -> List (Html Msg)
view (Model { form, postStatus }) =
    [ h1 [] [ text "Create Post" ]
    , viewForm form postStatus
    ]
        ++ viewStatus postStatus


viewForm : Form -> PostStatus -> Html Msg
viewForm form postStatus =
    let
        isDisabled =
            isFormInvalid form || postStatus == Pending
    in
    Html.form
        [ class "frame", onSubmit CreatePost ]
        [ viewTitleInput form.title
        , viewContentInput form.content
        , button
            [ type_ "submit", disabled isDisabled ]
            [ text "Create" ]
        ]


viewTitleInput : String -> Html Msg
viewTitleInput title =
    div
        [ class "frame" ]
        [ label [ style "display" "inline-block" ]
            [ div [] [ text "Title:" ]
            , input [ id createPostTitleId, type_ "text", value title, onInput UpdateTitle ] []
            ]
        ]


viewContentInput : String -> Html Msg
viewContentInput content =
    div
        [ class "frame" ]
        [ label []
            [ div [] [ text "Content:" ]
            , textarea [ value content, onInput UpdateContent ] []
            ]
        ]


viewStatus : PostStatus -> List (Html msg)
viewStatus postStatus =
    case postStatus of
        Failed error ->
            [ Styled.niceFrame [ text ("Creating post failed: " ++ Api.httpErrorToString error) ] ]

        _ ->
            []



-- HELPERS


toCreatePostMsg : Result Http.Error ( Post, Cmd Msg, Session ) -> Msg
toCreatePostMsg result =
    Api.toMsg CreatePostSuccess CreatePostFailure Logout result


createPostTitleId : String
createPostTitleId =
    "create-post-title"


focusTitleInput : Cmd Msg
focusTitleInput =
    Task.attempt (\_ -> NoOp) (Dom.focus createPostTitleId)


isFormInvalid : Form -> Bool
isFormInvalid { title, content } =
    title == "" || content == ""


updateTitle : SubModel -> String -> Model
updateTitle subModel newTitle =
    let
        { form } =
            subModel
    in
    Model { subModel | form = { form | title = newTitle } }


updateContent : SubModel -> String -> Model
updateContent subModel newContent =
    let
        { form } =
            subModel
    in
    Model { subModel | form = { form | content = newContent } }
