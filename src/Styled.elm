module Styled exposing (frame, niceFrame)

import Html exposing (Html)
import Html.Attributes exposing (class)



-- ELEMENTS


niceFrame : List (Html msg) -> Html msg
niceFrame children =
    Html.div [ class "nice-frame" ] children


frame : List (Html msg) -> Html msg
frame children =
    Html.div [ class "frame" ] children
