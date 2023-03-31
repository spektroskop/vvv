module Lib.Html exposing
    ( class
    , none
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
