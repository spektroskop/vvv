module Markdown exposing
    ( docs
    , render
    )

import Html exposing (Html)
import Lib.Attributes as Attributes
import Lib.Html as Html
import Markdown.Block as Block
import Markdown.Html as Markdown
import Markdown.Parser as Parser
import Markdown.Renderer as Renderer exposing (Renderer)


render : Renderer (Html msg) -> String -> Maybe (List (Html msg))
render renderer string =
    case Parser.parse string of
        Ok parsed ->
            Renderer.render renderer parsed
                |> Result.toMaybe

        Err _ ->
            Nothing


docs : Renderer (Html msg)
docs =
    { heading =
        \{ level, children } ->
            case level of
                Block.H1 ->
                    Html.h1 [] children

                Block.H2 ->
                    Html.h2 [] children

                Block.H3 ->
                    Html.h3 [] children

                Block.H4 ->
                    Html.h4 [] children

                Block.H5 ->
                    Html.h5 [] children

                Block.H6 ->
                    Html.h6 [] children
    , paragraph = Html.p []
    , blockQuote = Html.blockquote []
    , html = Markdown.oneOf []
    , text = Html.text
    , codeSpan = \code -> Html.code [] [ Html.text code ]
    , strong = Html.strong []
    , emphasis = Html.em []
    , strikethrough = Html.del []
    , hardLineBreak = Html.br [] []
    , link =
        \{ destination, title } ->
            Html.a
                [ Attributes.href destination
                , Attributes.target "_blank"
                , Attributes.rel "noopener noreferrer"
                , Maybe.map Attributes.title title
                    |> Maybe.withDefault Attributes.none
                ]
    , image = \_ -> Html.none
    , unorderedList = \_ -> Html.none
    , orderedList = \_ _ -> Html.none
    , codeBlock = \{ body } -> Html.pre [] [ Html.text body ]
    , thematicBreak = Html.hr [] []
    , table = Html.table []
    , tableHeader = Html.thead []
    , tableBody = Html.tbody []
    , tableRow = Html.tr []
    , tableCell = \_ -> Html.td []
    , tableHeaderCell = \_ -> Html.th []
    }
