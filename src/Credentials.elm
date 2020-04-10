module Credentials exposing
    ( Credentials
    , UpdateCredentialsData
    , encode
    , httpLogin
    , httpLoginTask
    , httpLogout
    , httpRegisterAndLogin
    , httpRegisterTask
    , httpUpdateCredentialsTask
    , toCredentials
    , toUpdateCredentialsData
    )

import Api exposing (toAuthHeader)
import Http exposing (Error, emptyBody)
import Json.Decode as D
import Json.Encode as E
import Session exposing (Session)
import Task exposing (Task)



-- MODEL


type alias Credentials =
    { username : String
    , password : String
    }


type alias UpdateCredentialsData =
    { password : String
    , newPassword : String
    }



-- HTTP CMDS


httpLogin : (Result Error Session -> msg) -> Credentials -> Cmd msg
httpLogin toLoginMsg credentials =
    Http.post
        { url = "/api/login"
        , body = Http.jsonBody (encode credentials)
        , expect = Http.expectJson toLoginMsg Session.decoder
        }


httpLogout : (Result Error () -> msg) -> Session -> Cmd msg
httpLogout toLogoutMsg session =
    Http.request
        { method = "POST"
        , headers = [ toAuthHeader session ]
        , url = "/api/logout"
        , body = emptyBody
        , expect = Http.expectWhatever toLogoutMsg
        , tracker = Nothing
        , timeout = Nothing
        }



-- HTTP TASKS


httpRegisterTask : Credentials -> Task Error ()
httpRegisterTask credentials =
    Http.task
        { method = "POST"
        , headers = []
        , url = "/api/users"
        , body = Http.jsonBody (encode credentials)
        , resolver = Api.taskResolver (\_ _ -> Ok ())
        , timeout = Nothing
        }


httpLoginTask : Credentials -> Task Http.Error Session
httpLoginTask credentials =
    Http.task
        { method = "POST"
        , headers = []
        , url = "/api/login"
        , body = Http.jsonBody (encode credentials)
        , resolver = Api.taskResolver decodeSession
        , timeout = Nothing
        }


httpRegisterAndLogin : Credentials -> Task Http.Error Session
httpRegisterAndLogin credentials =
    httpRegisterTask credentials
        |> Task.andThen (\_ -> httpLoginTask credentials)


httpUpdateCredentialsTask : Session -> UpdateCredentialsData -> Task Http.Error ( (), Cmd msg, Session )
httpUpdateCredentialsTask session updateCredentials =
    Api.httpTaskWithRefresh (httpUpdateCredentialsTask_ updateCredentials) session


httpUpdateCredentialsTask_ : UpdateCredentialsData -> Session -> Task Http.Error ()
httpUpdateCredentialsTask_ updateCredentials session =
    Http.task
        { method = "PATCH"
        , headers = [ Api.toAuthHeader session ]
        , url = "/api/users"
        , body = Http.jsonBody (encodeUpdateData updateCredentials)
        , resolver = Api.taskResolver (\_ _ -> Ok ())
        , timeout = Nothing
        }



-- HELPERS


encode : Credentials -> E.Value
encode { username, password } =
    E.object
        [ ( "username", E.string username )
        , ( "password", E.string password )
        ]


encodeUpdateData : UpdateCredentialsData -> E.Value
encodeUpdateData { password, newPassword } =
    E.object
        [ ( "password", E.string password )
        , ( "newPassword", E.string newPassword )
        ]


decodeSession : Http.Metadata -> String -> Result String Session
decodeSession _ body =
    D.decodeString Session.decoder body
        |> Result.mapError D.errorToString


toCredentials : { a | username : String, password : String } -> Credentials
toCredentials { username, password } =
    Credentials username password


toUpdateCredentialsData : { a | password : String, newPassword : String } -> UpdateCredentialsData
toUpdateCredentialsData { password, newPassword } =
    UpdateCredentialsData password newPassword
