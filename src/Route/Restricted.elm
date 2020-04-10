module Route.Restricted exposing
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
import Url.Parser as Parser exposing ((</>), Parser, int, map, oneOf, s, top)



-- MODEL


type Route
    = PostCreate
    | PostEdit Int
    | PostView Int
    | Posts
    | Settings



-- HELPERS


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Posts top
        , map PostCreate (s "posts" </> s "create")
        , map PostEdit (s "posts" </> int </> s "edit")
        , map PostView (s "posts" </> int)
        , map Settings (s "settings")
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
        Posts ->
            []

        PostCreate ->
            [ "posts", "create" ]

        PostEdit postId ->
            [ "posts", String.fromInt postId, "edit" ]

        PostView postId ->
            [ "posts", String.fromInt postId ]

        Settings ->
            [ "settings" ]


default : Route
default =
    Posts
