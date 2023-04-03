module Lib.Html exposing
    ( class
    , none
    , unless
    , when
    )

import Html exposing (Html, text)
import Html.Attributes


none : Html msg
none =
    text ""


class : List String -> Html.Attribute msg
class cs =
    String.join " " cs
        |> Html.Attributes.class


when : Bool -> (() -> Html msg) -> Html msg
when cond v =
    if cond then
        v ()

    else
        none


unless : Bool -> (() -> Html msg) -> Html msg
unless cond v =
    if cond then
        none

    else
        v ()
