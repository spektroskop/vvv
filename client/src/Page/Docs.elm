module Page.Docs exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser
import Html exposing (Html, div, text)
import Lib.Html exposing (class)
import Lib.Return as Return exposing (Return)


type Msg
    = Never


type alias Model =
    { section : Maybe String }


init : Maybe String -> ( Model, Cmd Msg )
init section =
    ( { section = section }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


document : Model -> Browser.Document Msg
document model =
    { title = "Docs"
    , body =
        [ div
            [ class
                [ "flex justify-center h-screen mt-10"
                , "font-bold text-2xl"
                ]
            ]
            [ text (Debug.toString model.section) ]
        ]
    }
