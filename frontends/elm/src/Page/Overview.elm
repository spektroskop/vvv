module Page.Overview exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser
import Html exposing (a, div, h1, text)
import Lib.Html exposing (class)
import Route


type Msg
    = Noop


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )


document : Model -> Browser.Document Msg
document _ =
    { title = "Overview"
    , body =
        let
            item id =
                a [ class [ "hover:underline" ], Route.href (Route.Detail id) ]
        in
        [ div
            [ class [ "flex flex-col items-center mt-10 gap-2" ] ]
            [ h1 [ class [ "font-bold text-2xl mb-5" ] ] [ text "Things" ]
            , item "a" [ text "Lorem ipsum dolor sit amet" ]
            , item "b" [ text "Etiam accumsan consequat" ]
            , item "c" [ text "Fusce in feugiat felis" ]
            ]
        ]
    }
