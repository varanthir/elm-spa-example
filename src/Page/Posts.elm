module Page.Posts exposing
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
import Html exposing (Html, a, b, button, h1, i, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, disabled, style)
import Html.Events exposing (onClick)
import Http
import Post exposing (Post)
import Route.Restricted exposing (href)
import Session exposing (Session)
import Styled
import Task



-- MODEL


type PostsStatus
    = PostsPending (Maybe (List Post))
    | PostsSuccess (List Post)
    | PostsFailed Http.Error
      -- Refresh after delete
    | PostsRefreshing (Maybe (List Post))


type DeleteStatus
    = DeleteNotStarted
    | DeletePending
    | DeleteSuccess
    | DeleteFailed Http.Error


type alias SubModel =
    { session : Session
    , postsStatus : PostsStatus
    , deleteStatus : DeleteStatus
    }


type Model
    = Model SubModel


initModel : Session -> Model
initModel session =
    Model
        { session = session
        , postsStatus = PostsPending Nothing
        , deleteStatus = DeleteNotStarted
        }


initCmd : Session -> Cmd Msg
initCmd session =
    getPostsCmd session


type Msg
    = GetPostsSuccess ( List Post, Cmd Msg )
    | GetPostsFailure Http.Error
    | GetPostsRetry
    | DeletePost Int
    | DeletePostSuccess ( (), Cmd Msg, Session )
    | DeletePostFailure Http.Error
    | Logout



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model subModel) =
    case msg of
        GetPostsSuccess ( posts, cmd ) ->
            ( Model { subModel | postsStatus = PostsSuccess posts }
            , cmd
            )

        GetPostsFailure error ->
            ( Model { subModel | postsStatus = PostsFailed error }
            , Cmd.none
            )

        GetPostsRetry ->
            ( Model { subModel | postsStatus = toPending subModel.postsStatus }
            , getPostsCmd subModel.session
            )

        DeletePost postId ->
            ( Model { subModel | deleteStatus = DeletePending }
            , Task.attempt toDeletePostMsg <|
                Post.httpDeletePostTask subModel.session postId
            )

        DeletePostFailure error ->
            ( Model { subModel | deleteStatus = DeleteFailed error }
            , Cmd.none
            )

        DeletePostSuccess ( (), cmd, session ) ->
            ( Model { subModel | postsStatus = toRefresh subModel.postsStatus, deleteStatus = DeleteSuccess }
            , Cmd.batch [ cmd, getPostsCmd session ]
            )

        Logout ->
            ( Model subModel
            , Session.storeCmd Nothing
            )


updateSession : Session -> Model -> Model
updateSession newSession (Model subModel) =
    Model { subModel | session = newSession }



-- VIEW


pageTitle : String
pageTitle =
    "Posts"


view : Model -> List (Html Msg)
view (Model { postsStatus, deleteStatus }) =
    let
        isPending =
            isAnyPending postsStatus deleteStatus

        content =
            case postsStatus of
                PostsPending (Just posts) ->
                    [ viewPostsTable isPending posts
                    , viewRefreshButton True
                    ]

                PostsPending Nothing ->
                    [ viewStatus "Loading..." ]

                PostsSuccess posts ->
                    [ viewPostsTable isPending posts
                    , viewRefreshButton isPending
                    ]

                PostsFailed error ->
                    [ viewRetryButton isPending
                    , viewStatus ("Getting posts failed: " ++ Api.httpErrorToString error)
                    ]

                PostsRefreshing (Just posts) ->
                    [ viewPostsTable isPending posts
                    , viewRefreshButton True
                    ]

                PostsRefreshing Nothing ->
                    [ viewRefreshButton isPending ]
    in
    h1 []
        [ text "Posts" ]
        :: content
        ++ viewDeleteStatus deleteStatus


viewPostsTable : Bool -> List Post -> Html Msg
viewPostsTable isPending posts =
    if List.isEmpty posts then
        Styled.niceFrame [ text "You do not have posts yet. You can create new one." ]

    else
        table []
            [ thead []
                [ tr []
                    [ th [ style "width" "30%" ] [ text "Title" ]
                    , th [ style "width" "60%" ] [ text "Content" ]
                    , th [] [ text "" ]
                    , th [] [ text "" ]
                    ]
                ]
            , tbody [] (List.map (viewPostRow isPending) posts)
            ]


viewPostRow : Bool -> Post -> Html Msg
viewPostRow isPending { id, title, content } =
    tr []
        [ td [ class "ellipsis" ] [ viewPostTitle id title ]
        , td [ class "ellipsis" ] [ viewPostContent content ]
        , td [] [ viewEditLink id ]
        , td [] [ viewDeleteButton isPending id ]
        ]


viewPostTitle : Int -> String -> Html Msg
viewPostTitle postId title =
    a
        [ href (Route.Restricted.PostView postId) ]
        [ b [] [ text title ] ]


viewPostContent : String -> Html Msg
viewPostContent content =
    i [] [ text content ]


viewEditLink : Int -> Html Msg
viewEditLink postId =
    a [ href (Route.Restricted.PostEdit postId) ] [ text "Edit" ]


viewDeleteButton : Bool -> Int -> Html Msg
viewDeleteButton isPending postId =
    button [ class "btn-flat", onClick (DeletePost postId), disabled isPending ] [ text "Delete" ]


viewRefreshButton : Bool -> Html Msg
viewRefreshButton isDisabled =
    button [ disabled isDisabled, onClick GetPostsRetry ] [ text "Refresh" ]


viewRetryButton : Bool -> Html Msg
viewRetryButton isDisabled =
    button [ disabled isDisabled, onClick GetPostsRetry ] [ text "Retry" ]


viewStatus : String -> Html Msg
viewStatus status =
    Styled.niceFrame [ text status ]


viewDeleteStatus : DeleteStatus -> List (Html Msg)
viewDeleteStatus deleteStatus =
    case deleteStatus of
        DeleteFailed error ->
            [ viewStatus ("Can't delete post: " ++ Api.httpErrorToString error) ]

        _ ->
            []



-- HELPERS


getPostsCmd : Session -> Cmd Msg
getPostsCmd session =
    Task.attempt toGetPostsMsg <|
        Post.httpGetPostsTask session


toMsg : (( a, Cmd Msg ) -> Msg) -> (Http.Error -> Msg) -> Result Http.Error ( a, Cmd Msg, Session ) -> Msg
toMsg msgSuccess msgFailure result =
    Api.toMsg msgSuccess msgFailure Logout result


toGetPostsMsg : Result Http.Error ( List Post, Cmd Msg, Session ) -> Msg
toGetPostsMsg result =
    toMsg GetPostsSuccess GetPostsFailure result


toDeletePostMsg : Result Http.Error ( (), Cmd Msg, Session ) -> Msg
toDeletePostMsg result =
    Api.toMsgWithSession DeletePostSuccess DeletePostFailure Logout result


toPending : PostsStatus -> PostsStatus
toPending postsStatus =
    case postsStatus of
        PostsPending _ ->
            postsStatus

        PostsSuccess posts ->
            PostsPending (Just posts)

        PostsFailed _ ->
            PostsPending Nothing

        PostsRefreshing maybePosts ->
            PostsPending maybePosts


toRefresh : PostsStatus -> PostsStatus
toRefresh postsStatus =
    case postsStatus of
        PostsPending maybePosts ->
            PostsRefreshing maybePosts

        PostsSuccess posts ->
            PostsRefreshing (Just posts)

        PostsFailed _ ->
            PostsRefreshing Nothing

        PostsRefreshing _ ->
            postsStatus


isAnyPending : PostsStatus -> DeleteStatus -> Bool
isAnyPending postsStatus deleteStatus =
    case postsStatus of
        PostsPending _ ->
            True

        PostsRefreshing _ ->
            True

        _ ->
            deleteStatus == DeletePending
