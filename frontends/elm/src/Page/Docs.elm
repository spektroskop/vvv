module Page.Docs exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser
import Html exposing (div, h1, text)
import Lib.Html exposing (class)


type Msg
    = Noop


type alias Model =
    { fragment : Maybe String }


init : Maybe String -> ( Model, Cmd Msg )
init fragment =
    ( { fragment = fragment }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )


document : Model -> Browser.Document Msg
document model =
    { title = "Docs"
    , body =
        [ div
            [ class [ "flex flex-row justify-center mt-10 gap-2" ] ]
            [ h1 [ class [ "font-bold text-2xl mb-5 text-shadow" ] ]
                [ case model.fragment of
                    Nothing ->
                        text "—"

                    Just fragment ->
                        text ("#" ++ fragment)
                ]
            ]
        ]
    }
