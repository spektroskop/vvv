module Lib.Html.Builder exposing
    ( Builder(..)
    , Node
    , attributes
    , body
    , build
    , classes
    , new
    , wrap
    , wrapNode
    )

import Html exposing (Html)
import Html.Attributes
import Lib.Basics exposing (flip)
import Lib.List as List


type alias Node msg =
    List (Html.Attribute msg) -> List (Html msg) -> Html msg


type Builder msg
    = Builder
        { node : Node msg
        , attributes : List (Html.Attribute msg)
        , classes : List String
        , body : List (Html msg)
        , parent : Maybe (Builder msg)
        }


new : Node msg -> Builder msg
new node =
    Builder
        { node = node
        , attributes = []
        , classes = []
        , body = []
        , parent = Nothing
        }


attributes : List (Html.Attribute msg) -> Builder msg -> Builder msg
attributes v (Builder b) =
    Builder { b | attributes = List.concat [ b.attributes, v ] }


classes : List String -> Builder msg -> Builder msg
classes v (Builder b) =
    Builder { b | classes = List.concat [ b.classes, v ] }


body : List (Html msg) -> Builder msg -> Builder msg
body v (Builder b) =
    Builder { b | body = List.concat [ b.body, v ] }


wrapNode : Node msg -> Builder msg -> Builder msg
wrapNode node parent =
    wrap (new node) parent


wrap : Builder msg -> Builder msg -> Builder msg
wrap (Builder b) parent =
    Builder { b | parent = Just parent }


build : Builder msg -> Html msg
build (Builder b) =
    let
        self =
            String.join " " b.classes
                |> Html.Attributes.class
                |> List.prepend b.attributes
                |> flip b.node b.body
    in
    Maybe.map (build << body [ self ]) b.parent
        |> Maybe.withDefault self
