module Lib.Html exposing (class)

import Html
import Html.Attributes


class : List String -> Html.Attribute msg
class cs =
    String.join " " cs
        |> Html.Attributes.class
