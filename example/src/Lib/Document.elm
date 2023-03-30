module Lib.Document exposing (join, map, none, placeholder)

import Browser
import Html exposing (text)


placeholder : String -> Browser.Document msg
placeholder v =
    { title = v, body = [ text v ] }


none : Browser.Document msg
none =
    { title = "", body = [] }


map : (a -> b) -> Browser.Document a -> Browser.Document b
map f doc =
    { title = doc.title
    , body = List.map (Html.map f) doc.body
    }


join : String -> List (Browser.Document msg) -> Browser.Document msg
join separator docs =
    { title =
        List.reverse docs
            |> List.map .title
            |> List.filter (not << String.isEmpty)
            |> String.join separator
    , body = List.concatMap .body docs
    }
