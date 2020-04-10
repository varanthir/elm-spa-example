module Api exposing
    ( httpErrorToString
    , httpTaskWithRefresh
    , taskResolver
    , toAuthHeader
    , toMsg
    , toMsgWithSession
    )

import Http exposing (Error(..), Header, Metadata, Resolver, Response(..))
import Json.Decode as D
import Json.Encode as E
import Session exposing (Session)
import Task exposing (Task)



-- HTTP


httpRefreshTask : Session -> Task Error Session
httpRefreshTask session =
    Http.task
        { method = "POST"
        , headers = []
        , url = "/api/refresh"
        , body = Http.jsonBody <| encodeRefreshToken session
        , resolver = taskResolver decodeSession
        , timeout = Nothing
        }


httpTaskWithRefresh :
    (Session -> Task Error r)
    -> Session
    -> Task Error ( r, Cmd msg, Session )
httpTaskWithRefresh httpTask session =
    let
        httpTaskRepeat newSession =
            httpTask newSession
                |> Task.map (\body -> ( body, Session.storeCmd (Just newSession), newSession ))

        tryRefresh error =
            if error == BadStatus 401 then
                httpRefreshTask session
                    |> Task.andThen httpTaskRepeat

            else
                Task.fail error
    in
    httpTask session
        |> Task.map (\body -> ( body, Cmd.none, session ))
        |> Task.onError tryRefresh



-- HELPERS


decodeSession : Metadata -> String -> Result String Session
decodeSession _ body =
    D.decodeString Session.decoder body
        |> Result.mapError D.errorToString


taskResolver : (Metadata -> String -> Result String a) -> Resolver Error a
taskResolver decode =
    Http.stringResolver <|
        \response ->
            case response of
                BadUrl_ url ->
                    Err (BadUrl url)

                Timeout_ ->
                    Err Timeout

                NetworkError_ ->
                    Err NetworkError

                BadStatus_ { statusCode } _ ->
                    Err (BadStatus statusCode)

                GoodStatus_ metadata body ->
                    decode metadata body
                        |> Result.mapError BadBody


encodeRefreshToken : Session -> E.Value
encodeRefreshToken session =
    let
        refreshToken =
            Session.toRefreshToken session
    in
    E.object
        [ ( "refresh_token", E.string refreshToken ) ]


toMsg :
    (( a, Cmd msg ) -> msg)
    -> (Error -> msg)
    -> msg
    -> Result Error ( a, Cmd msg, Session )
    -> msg
toMsg msgSuccess msgFailure msgLogout result =
    case result of
        Ok ( data, cmd, _ ) ->
            msgSuccess ( data, cmd )

        Err (BadStatus 401) ->
            msgLogout

        Err error ->
            msgFailure error


toMsgWithSession :
    (( a, Cmd msg, Session ) -> msg)
    -> (Error -> msg)
    -> msg
    -> Result Error ( a, Cmd msg, Session )
    -> msg
toMsgWithSession msgSuccess msgFailure msgLogout result =
    case result of
        Ok ( data, cmd, session ) ->
            msgSuccess ( data, cmd, session )

        Err (BadStatus 401) ->
            msgLogout

        Err error ->
            msgFailure error


toAuthHeader : Session -> Header
toAuthHeader session =
    Http.header "Authorization" ("Bearer " ++ Session.toAccessToken session)


httpErrorToString : Error -> String
httpErrorToString error =
    case error of
        BadUrl text ->
            "BadUrl: " ++ text

        Timeout ->
            "Timeout"

        NetworkError ->
            "NetworkError"

        BadStatus status ->
            "BadStatus: " ++ String.fromInt status

        BadBody text ->
            "BadBody: " ++ text
