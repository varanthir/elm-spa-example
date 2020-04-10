module Route exposing
    ( Route(..)
    , defaultOpen
    , defaultRestricted
    , fromUrl
    , href
    , toString
    )

import Html exposing (Attribute)
import Html.Attributes as Attr
import Route.Open as Open
import Route.Restricted as Restricted
import Url exposing (Url)
import Url.Parser as Parser



-- MODEL


type Route
    = Restricted Restricted.Route
    | Open Open.Route



-- HELPERS


fromUrl : Url -> Maybe Route
fromUrl url =
    let
        maybeRestrictedRoute =
            Parser.parse Restricted.parser url
                |> Maybe.map Restricted
    in
    case maybeRestrictedRoute of
        Just restrictedRoute ->
            Just restrictedRoute

        _ ->
            Parser.parse Open.parser url
                |> Maybe.map Open


href : Route -> Attribute msg
href targetRoute =
    Attr.href (toString targetRoute)


toString : Route -> String
toString page =
    "/" ++ String.join "/" (routeToPieces page)


routeToPieces : Route -> List String
routeToPieces route =
    case route of
        Restricted restrictedRoute ->
            Restricted.toPieces restrictedRoute

        Open openRoute ->
            Open.toPieces openRoute


defaultOpen : Route
defaultOpen =
    Open Open.default


defaultRestricted : Route
defaultRestricted =
    Restricted Restricted.default
