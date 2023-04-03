module Lib.Svg exposing
    ( class
    , d
    )

import Svg
import Svg.Attributes


class : List String -> Svg.Attribute msg
class vs =
    String.join " " vs
        |> Svg.Attributes.class


d : List String -> Svg.Attribute msg
d vs =
    String.join " " vs
        |> Svg.Attributes.d
