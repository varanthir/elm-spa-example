module Header exposing (view)

import Html exposing (Html, a, button, header, li, nav, text, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Route exposing (href)
import Route.Open as Open
import Route.Restricted as Restricted
import Session exposing (Session)



-- VIEW


view : (Session -> msg) -> Maybe Session -> Html msg
view toLogoutMsg maybeSession =
    header [ class "nice-frame" ] [ viewNav toLogoutMsg maybeSession ]


viewNav : (Session -> msg) -> Maybe Session -> Html msg
viewNav toLogoutMsg maybeSession =
    let
        links =
            case maybeSession of
                Nothing ->
                    viewOpenLinks

                Just session ->
                    viewRestrictedLinks <| toLogoutMsg session
    in
    nav
        [ class "nice-nav" ]
        [ ul [] <| List.intersperse (text " · ") links
        ]


viewOpenLinks : List (Html msg)
viewOpenLinks =
    [ viewOpenLink Open.Login "Login"
    , viewOpenLink Open.Register "Register"
    ]


viewRestrictedLinks : msg -> List (Html msg)
viewRestrictedLinks toLogoutMsg =
    [ viewRestrictedLink Restricted.Posts "Posts"
    , viewRestrictedLink Restricted.PostCreate "Create Post"
    , viewRestrictedLink Restricted.Settings "Settings"
    , li [] [ button [ onClick toLogoutMsg ] [ text "Logout" ] ]
    ]


viewOpenLink : Open.Route -> String -> Html msg
viewOpenLink route string =
    li [] [ a [ Open.href route ] [ text string ] ]


viewRestrictedLink : Restricted.Route -> String -> Html msg
viewRestrictedLink route string =
    li [] [ a [ Restricted.href route ] [ text string ] ]
