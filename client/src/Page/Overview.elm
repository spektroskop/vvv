module Page.Overview exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser
import Html exposing (Html, a, div, h1, text)
import Lib.Html exposing (class)
import Lib.Return as Return exposing (Return)
import Route


type Msg
    = Never


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


document : Model -> Browser.Document Msg
document model =
    { title = "Overview"
    , body =
        let
            item id =
                a [ class [ "hover:underline" ], Route.href (Route.Detail id) ]
        in
        [ div
            [ class [ "flex flex-col items-center mt-10 gap-2" ] ]
            [ h1 [ class [ "font-bold text-2xl mb-5" ] ] [ text "Things" ]
            , item "Lorem" [ text "Lorem ipsum dolor sit amet" ]
            , item "Etiam" [ text "Etiam accumsan consequat" ]
            , item "Fusce" [ text "Fusce in feugiat felis" ]
            ]
        ]
    }
