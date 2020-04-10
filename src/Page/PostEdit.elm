module Page.PostEdit exposing
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
import Html.Events exposing (onClick, onInput, onSubmit)
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


type GetPostStatus
    = GetPending
    | GetSuccess Post
    | GetFailed Http.Error


type UpdatePostStatus
    = UpdateNotStarted
    | UpdatePending
    | UpdateFailed Http.Error


type alias SubModel =
    { session : Session
    , navKey : Nav.Key
    , postId : Int
    , form : Form
    , getPostStatus : GetPostStatus
    , updatePostStatus : UpdatePostStatus
    }


type Model
    = Model SubModel


initModel : Session -> Nav.Key -> Int -> Model
initModel session navKey postId =
    Model
        { session = session
        , navKey = navKey
        , postId = postId
        , form = Form "" ""
        , getPostStatus = GetPending
        , updatePostStatus = UpdateNotStarted
        }


initCmd : Session -> Int -> Cmd Msg
initCmd session postId =
    getPostCmd session postId


type Msg
    = NoOp
    | UpdateTitle String
    | UpdateContent String
    | GetPostRetry
    | GetPostSuccess ( Post, Cmd Msg )
    | GetPostFailure Http.Error
    | UpdatePost
    | UpdatePostSuccess ( Post, Cmd Msg )
    | UpdatePostFailure Http.Error
    | Logout



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model subModel) =
    case msg of
        UpdateTitle newTitle ->
            ( updateTitle subModel newTitle
            , Cmd.none
            )

        UpdateContent newContent ->
            ( updateContent subModel newContent
            , Cmd.none
            )

        GetPostRetry ->
            ( Model { subModel | getPostStatus = GetPending }
            , getPostCmd subModel.session subModel.postId
            )

        GetPostSuccess ( post, cmd ) ->
            ( Model { subModel | getPostStatus = GetSuccess post, form = Form post.title post.content }
            , Cmd.batch [ focusTitleInput, cmd ]
            )

        GetPostFailure error ->
            ( Model { subModel | getPostStatus = GetFailed error }
            , Cmd.none
            )

        UpdatePost ->
            ( Model { subModel | updatePostStatus = UpdatePending }
            , Task.attempt toUpdatePostMsg <|
                Post.httpUpdatePostTask subModel.session subModel.postId (Post.toPostData subModel.form)
            )

        UpdatePostSuccess ( post, cmd ) ->
            ( Model subModel
            , Cmd.batch
                [ cmd
                , Nav.replaceUrl subModel.navKey <|
                    Route.Restricted.toString (Route.Restricted.PostView post.id)
                ]
            )

        UpdatePostFailure error ->
            ( Model { subModel | updatePostStatus = UpdateFailed error }
            , Cmd.none
            )

        Logout ->
            ( Model subModel
            , Session.storeCmd Nothing
            )

        NoOp ->
            ( Model subModel, Cmd.none )


updateSession : Session -> Model -> Model
updateSession newSession (Model subModel) =
    Model { subModel | session = newSession }



-- VIEW


pageTitle : String
pageTitle =
    "Edit Post"


view : Model -> List (Html Msg)
view (Model { form, getPostStatus, updatePostStatus }) =
    let
        viewContent =
            case getPostStatus of
                GetPending ->
                    [ viewStatus "Loading..." ]

                GetSuccess _ ->
                    [ viewForm form updatePostStatus ]

                GetFailed error ->
                    [ viewStatus ("Getting post failed: " ++ Api.httpErrorToString error)
                    , viewRetryButton
                    ]
    in
    h1 []
        [ text "Edit Post" ]
        :: viewContent
        ++ viewUpdatePostStatus updatePostStatus


viewForm : Form -> UpdatePostStatus -> Html Msg
viewForm form updatePostStatus =
    let
        isDisabled =
            isFormInvalid form || updatePostStatus == UpdatePending
    in
    Html.form
        [ class "frame", onSubmit UpdatePost ]
        [ viewTitleInput form.title
        , viewContentInput form.content
        , button [ type_ "submit", disabled isDisabled ] [ text "Update" ]
        ]


viewTitleInput : String -> Html Msg
viewTitleInput title =
    div
        [ class "frame" ]
        [ label [ style "display" "inline-block" ]
            [ div [] [ text "Title:" ]
            , input [ id editPostTitleId, type_ "text", value title, onInput UpdateTitle ] []
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


viewRetryButton : Html Msg
viewRetryButton =
    button [ onClick GetPostRetry ] [ text "Retry" ]


viewStatus : String -> Html Msg
viewStatus status =
    Styled.niceFrame [ text status ]


viewUpdatePostStatus : UpdatePostStatus -> List (Html Msg)
viewUpdatePostStatus updatePostStatus =
    case updatePostStatus of
        UpdateFailed error ->
            [ viewStatus ("Updating post failed: " ++ Api.httpErrorToString error) ]

        _ ->
            []



-- HELPERS


getPostCmd : Session -> Int -> Cmd Msg
getPostCmd session postId =
    Task.attempt toGetPostMsg <|
        Post.httpGetPostTask session postId


toMsg : (( a, Cmd Msg ) -> Msg) -> (Http.Error -> Msg) -> Result Http.Error ( a, Cmd Msg, Session ) -> Msg
toMsg msgSuccess msgFailure result =
    Api.toMsg msgSuccess msgFailure Logout result


toGetPostMsg : Result Http.Error ( Post, Cmd Msg, Session ) -> Msg
toGetPostMsg result =
    toMsg GetPostSuccess GetPostFailure result


toUpdatePostMsg : Result Http.Error ( Post, Cmd Msg, Session ) -> Msg
toUpdatePostMsg result =
    toMsg UpdatePostSuccess UpdatePostFailure result


editPostTitleId : String
editPostTitleId =
    "create-post-title"


focusTitleInput : Cmd Msg
focusTitleInput =
    Task.attempt (\_ -> NoOp) (Dom.focus editPostTitleId)


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


isFormInvalid : Form -> Bool
isFormInvalid { title, content } =
    title == "" || content == ""
