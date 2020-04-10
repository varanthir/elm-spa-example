module Route.Open exposing
    ( Route(..)
    , default
    , fromUrl
    , href
    , parser
    , toPieces
    , toString
    )

import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, map, oneOf, s)



-- MODEL


type Route
    = Login
    | Register



-- HELPERS


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Login (s "login")
        , map Register (s "register")
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


href : Route -> Attribute msg
href targetRoute =
    Attr.href (toString targetRoute)


toString : Route -> String
toString page =
    "/" ++ String.join "/" (toPieces page)


toPieces : Route -> List String
toPieces route =
    case route of
        Login ->
            [ "login" ]

        Register ->
            [ "register" ]


default : Route
default =
    Login
