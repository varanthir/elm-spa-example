module Post exposing
    ( Post
    , PostData
    , httpCreatePostTask
    , httpDeletePostTask
    , httpGetPostTask
    , httpGetPostsTask
    , httpUpdatePostTask
    , toPostData
    )

import Api
import Http
import Json.Decode as D
import Json.Encode as E
import Session exposing (Session)
import Task exposing (Task)



-- MODEL


type alias Post =
    { id : Int
    , title : String
    , content : String
    }


type alias PostData =
    { title : String
    , content : String
    }



-- HTTP


httpGetPostTask : Session -> Int -> Task Http.Error ( Post, Cmd msg, Session )
httpGetPostTask session postId =
    Api.httpTaskWithRefresh (httpGetPostTask_ postId) session


httpGetPostsTask : Session -> Task Http.Error ( List Post, Cmd msg, Session )
httpGetPostsTask session =
    Api.httpTaskWithRefresh httpGetPostsTask_ session


httpCreatePostTask : Session -> PostData -> Task Http.Error ( Post, Cmd msg, Session )
httpCreatePostTask session postData =
    Api.httpTaskWithRefresh (httpCreatePostTask_ postData) session


httpUpdatePostTask : Session -> Int -> PostData -> Task Http.Error ( Post, Cmd msg, Session )
httpUpdatePostTask session postId postData =
    Api.httpTaskWithRefresh (httpUpdatePostTask_ postId postData) session


httpDeletePostTask : Session -> Int -> Task Http.Error ( (), Cmd msg, Session )
httpDeletePostTask session postId =
    Api.httpTaskWithRefresh (httpDeletePostTask_ postId) session


httpGetPostTask_ : Int -> Session -> Task Http.Error Post
httpGetPostTask_ postId session =
    Http.task
        { method = "GET"
        , headers = [ Api.toAuthHeader session ]
        , url = "/api/posts/" ++ String.fromInt postId
        , body = Http.emptyBody
        , resolver = Api.taskResolver decodePost
        , timeout = Nothing
        }


httpGetPostsTask_ : Session -> Task Http.Error (List Post)
httpGetPostsTask_ session =
    Http.task
        { method = "GET"
        , headers = [ Api.toAuthHeader session ]
        , url = "/api/posts"
        , body = Http.emptyBody
        , resolver = Api.taskResolver decodePosts
        , timeout = Nothing
        }


httpCreatePostTask_ : PostData -> Session -> Task Http.Error Post
httpCreatePostTask_ postData session =
    Http.task
        { method = "POST"
        , headers = [ Api.toAuthHeader session ]
        , url = "/api/posts"
        , body = Http.jsonBody (postDataEncoder postData)
        , resolver = Api.taskResolver decodePost
        , timeout = Nothing
        }


httpUpdatePostTask_ : Int -> PostData -> Session -> Task Http.Error Post
httpUpdatePostTask_ postId postData session =
    Http.task
        { method = "PATCH"
        , headers = [ Api.toAuthHeader session ]
        , url = "/api/posts/" ++ String.fromInt postId
        , body = Http.jsonBody (postDataEncoder postData)
        , resolver = Api.taskResolver decodePost
        , timeout = Nothing
        }


httpDeletePostTask_ : Int -> Session -> Task Http.Error ()
httpDeletePostTask_ postId session =
    Http.task
        { method = "DELETE"
        , headers = [ Api.toAuthHeader session ]
        , url = "/api/posts/" ++ String.fromInt postId
        , body = Http.emptyBody
        , resolver = Api.taskResolver (\_ _ -> Ok ())
        , timeout = Nothing
        }



-- DECODERS


postDataEncoder : PostData -> E.Value
postDataEncoder { title, content } =
    E.object
        [ ( "title", E.string title )
        , ( "content", E.string content )
        ]


postDecoder : D.Decoder Post
postDecoder =
    D.map3 Post
        (D.field "id" D.int)
        (D.field "title" D.string)
        (D.field "content" D.string)


postsDecoder : D.Decoder (List Post)
postsDecoder =
    D.list postDecoder



-- HELPERS


toPostData : { a | title : String, content : String } -> PostData
toPostData { title, content } =
    PostData title content


decodePost : Http.Metadata -> String -> Result String Post
decodePost _ body =
    D.decodeString postDecoder body
        |> Result.mapError D.errorToString


decodePosts : Http.Metadata -> String -> Result String (List Post)
decodePosts _ body =
    D.decodeString postsDecoder body
        |> Result.mapError D.errorToString
