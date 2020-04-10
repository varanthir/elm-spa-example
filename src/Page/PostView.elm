module Page.PostView exposing
    ( Model
    , Msg
    , initCmd
    , initModel
    , pageTitle
    , toPostId
    , update
    , updateSession
    , view
    )

import Api
import Browser.Navigation as Nav
import Html exposing (Html, a, br, button, div, h1, h2, p, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Http
import Post exposing (Post)
import Route.Restricted exposing (href)
import Session exposing (Session)
import Styled
import Task



-- MODEL


type PostStatus
    = PostPending (Maybe Post)
    | PostSuccess Post
    | PostFailed Http.Error


type DeleteStatus
    = DeleteNotStarted
    | DeletePending
    | DeleteFailed Http.Error


type alias SubModel =
    { session : Session
    , navKey : Nav.Key
    , postId : Int
    , postStatus : PostStatus
    , deleteStatus : DeleteStatus
    }


type Model
    = Model SubModel


initModel : Session -> Nav.Key -> Int -> Model
initModel session navKey postId =
    Model
        { session = session
        , navKey = navKey
        , postId = postId
        , postStatus = PostPending Nothing
        , deleteStatus = DeleteNotStarted
        }


initCmd : Session -> Int -> Cmd Msg
initCmd session postId =
    getPostCmd session postId


type Msg
    = GetPostSuccess ( Post, Cmd Msg )
    | GetPostFailure Http.Error
    | GetPostRetry
    | DeletePost
    | DeletePostSuccess ( (), Cmd Msg )
    | DeletePostFailure Http.Error
    | Logout



-- UPDATE


updateSession : Session -> Model -> Model
updateSession session (Model submodel) =
    Model { submodel | session = session }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model subModel) =
    case msg of
        GetPostSuccess ( post, cmd ) ->
            ( Model { subModel | postStatus = PostSuccess post }
            , cmd
            )

        GetPostFailure error ->
            ( Model { subModel | postStatus = PostFailed error }
            , Cmd.none
            )

        GetPostRetry ->
            ( Model { subModel | postStatus = toPending subModel.postStatus }
            , getPostCmd subModel.session subModel.postId
            )

        DeletePost ->
            ( Model { subModel | deleteStatus = DeletePending }
            , Task.attempt toDeletePostMsg <|
                Post.httpDeletePostTask subModel.session subModel.postId
            )

        DeletePostSuccess ( (), cmd ) ->
            ( Model subModel
            , Cmd.batch
                [ cmd
                , Nav.replaceUrl subModel.navKey (Route.Restricted.toString Route.Restricted.Posts)
                ]
            )

        DeletePostFailure error ->
            ( Model { subModel | deleteStatus = DeleteFailed error }
            , Cmd.none
            )

        Logout ->
            ( Model subModel
            , Session.storeCmd Nothing
            )



-- VIEW


pageTitle : String
pageTitle =
    "Post"


view : Model -> List (Html Msg)
view (Model { postStatus, postId, deleteStatus }) =
    let
        isDisabled =
            isAnyPending postStatus deleteStatus

        viewContent =
            case postStatus of
                PostPending Nothing ->
                    [ viewStatus "Loading..." ]

                PostPending (Just post) ->
                    viewPost post
                        ++ [ viewActions postId isDisabled deleteStatus
                           , viewRefreshButton True
                           ]

                PostSuccess post ->
                    viewPost post
                        ++ [ viewActions postId isDisabled deleteStatus
                           , viewRefreshButton isDisabled
                           ]

                PostFailed error ->
                    [ viewStatus ("Getting post failed: " ++ Api.httpErrorToString error)
                    , viewRetryButton
                    ]
    in
    h1 []
        [ text "Post" ]
        :: viewContent


viewPost : Post -> List (Html Msg)
viewPost { title, content } =
    [ h2 [] [ text title ]
    , p [ class "nice-frame" ] (viewPostLines content)
    ]


viewPostLines : String -> List (Html Msg)
viewPostLines content =
    String.split "\n" (content ++ "\n")
        |> List.map (\line -> text line)
        |> List.intersperse (br [] [])


viewActions : Int -> Bool -> DeleteStatus -> Html Msg
viewActions postId isDisabled deleteStatus =
    let
        viewAnchor =
            if isDisabled then
                text "Edit"

            else
                a [ href (Route.Restricted.PostEdit postId) ] [ text "Edit" ]

        viewDeleteStatus =
            case deleteStatus of
                DeleteFailed error ->
                    [ viewStatus ("Delete failed: " ++ Api.httpErrorToString error) ]

                _ ->
                    []

        viewContent =
            [ viewAnchor
            , text " · "
            , button [ disabled isDisabled, onClick DeletePost ] [ text "Delete" ]
            ]
    in
    div [ class "frame" ] <|
        viewContent
            ++ viewDeleteStatus


viewRetryButton : Html Msg
viewRetryButton =
    button [ onClick GetPostRetry ] [ text "Retry" ]


viewStatus : String -> Html Msg
viewStatus status =
    Styled.niceFrame [ text status ]



-- HELPERS


getPostCmd : Session -> Int -> Cmd Msg
getPostCmd session postId =
    Task.attempt toGetPostMsg <|
        Post.httpGetPostTask session postId


viewRefreshButton : Bool -> Html Msg
viewRefreshButton isDisabled =
    button
        [ disabled isDisabled, onClick GetPostRetry ]
        [ text "Refresh" ]


toMsg : (( a, Cmd Msg ) -> Msg) -> (Http.Error -> Msg) -> Result Http.Error ( a, Cmd Msg, Session ) -> Msg
toMsg msgSuccess msgFailure result =
    Api.toMsg msgSuccess msgFailure Logout result


toGetPostMsg : Result Http.Error ( Post, Cmd Msg, Session ) -> Msg
toGetPostMsg result =
    toMsg GetPostSuccess GetPostFailure result


toDeletePostMsg : Result Http.Error ( (), Cmd Msg, Session ) -> Msg
toDeletePostMsg result =
    toMsg DeletePostSuccess DeletePostFailure result


toPending : PostStatus -> PostStatus
toPending postStatus =
    case postStatus of
        PostPending _ ->
            postStatus

        PostSuccess post ->
            PostPending (Just post)

        _ ->
            PostPending Nothing


isAnyPending : PostStatus -> DeleteStatus -> Bool
isAnyPending postStatus deleteStatus =
    case postStatus of
        PostPending _ ->
            True

        _ ->
            deleteStatus == DeletePending


toPostId : Model -> Int
toPostId (Model { postId }) =
    postId
