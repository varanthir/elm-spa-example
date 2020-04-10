module User exposing (User, httpGetUserTask)

import Api exposing (toAuthHeader)
import Http exposing (Error, emptyBody)
import Json.Decode as D
import Session exposing (Session)
import Task exposing (Task)



-- MODEL


type alias User =
    { id : Int
    , username : String
    }



-- HTTP


httpGetUserTask : Session -> Task Error ( User, Cmd msg, Session )
httpGetUserTask session =
    Api.httpTaskWithRefresh httpGetUserTask_ session


httpGetUserTask_ : Session -> Task Error User
httpGetUserTask_ session =
    Http.task
        { method = "GET"
        , headers = [ Api.toAuthHeader session ]
        , url = "/api/me"
        , body = Http.emptyBody
        , resolver = Api.taskResolver decodeUser
        , timeout = Nothing
        }



-- DECODERS


decoder : D.Decoder User
decoder =
    D.map2 User
        (D.field "id" D.int)
        (D.field "username" D.string)



-- HELPERS


decodeUser : Http.Metadata -> String -> Result String User
decodeUser _ body =
    D.decodeString decoder body
        |> Result.mapError D.errorToString
