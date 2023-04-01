module Route exposing
    ( Route(..)
    , fromUrl
    , href
    , push
    , replace
    , toString
    )

import Browser.Navigation as Navigation
import Html
import Html.Attributes exposing (href)
import Url exposing (Url)
import Url.Parser as Url exposing ((</>))


type Route
    = Top
    | Example


fromUrl : Url -> Maybe Route
fromUrl =
    Url.parse (Url.oneOf routes)


routes : List (Url.Parser (Route -> a) a)
routes =
    [ Url.map Top Url.top
    , Url.map Example (Url.s "example")
    ]


toString : Route -> String
toString route =
    let
        join segments =
            "/" ++ String.join "/" segments
    in
    case route of
        Top ->
            join []

        Example ->
            join [ "example" ]


href : Route -> Html.Attribute msg
href route =
    Html.Attributes.href (toString route)


replace : Navigation.Key -> Route -> Cmd msg
replace key route =
    Navigation.replaceUrl key (toString route)


push : Navigation.Key -> Route -> Cmd msg
push key route =
    Navigation.pushUrl key (toString route)
