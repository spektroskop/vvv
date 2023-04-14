module Lib.Attributes exposing
    ( class
    , none
    )

import Html
import Html.Attributes


none : Html.Attribute msg
none =
    class []


class : List String -> Html.Attribute msg
class cs =
    String.join " " cs
        |> Html.Attributes.class
