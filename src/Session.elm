port module Session exposing (Session, changes, decode, decoder, storeCmd, toAccessToken, toRefreshToken)

import Json.Decode as D
import Json.Encode as E
import Result exposing (andThen, toMaybe)



-- MODEL


type alias SessionDetails =
    { refreshToken : String
    , accessToken : String
    }


type Session
    = Session SessionDetails



-- OUTGOING PORT


port store : Maybe String -> Cmd msg


storeCmd : Maybe Session -> Cmd msg
storeCmd maybeSession =
    store (Maybe.map encode maybeSession)



-- INCOMING PORT


port onChange : (D.Value -> msg) -> Sub msg


changes : (Maybe Session -> msg) -> Sub msg
changes toMsg =
    onChange (\value -> toMsg (decode value))



-- HELPERS


decode : D.Value -> Maybe Session
decode value =
    D.decodeValue D.string value
        |> andThen (D.decodeString localStorageDecoder)
        |> toMaybe


decoder : D.Decoder Session
decoder =
    D.map Session <|
        D.map2 SessionDetails
            (D.field "refresh_token" D.string)
            (D.field "access_token" D.string)


localStorageDecoder : D.Decoder Session
localStorageDecoder =
    D.map Session <|
        D.map2 SessionDetails
            (D.field "refreshToken" D.string)
            (D.field "accessToken" D.string)


encode : Session -> String
encode (Session { refreshToken, accessToken }) =
    E.encode 0 <|
        E.object
            [ ( "refreshToken", E.string refreshToken )
            , ( "accessToken", E.string accessToken )
            ]


toRefreshToken : Session -> String
toRefreshToken (Session { refreshToken }) =
    refreshToken


toAccessToken : Session -> String
toAccessToken (Session { accessToken }) =
    accessToken
