module Page.Detail exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser
import Html exposing (div, text)
import Lib.Html exposing (class)


type Msg
    = Noop


type alias Model =
    { id : String }


init : String -> ( Model, Cmd Msg )
init id =
    ( { id = id }, Cmd.none )


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
    { title = model.id
    , body =
        [ div
            [ class
                [ "flex justify-center h-screen mt-10"
                , "font-bold text-2xl"
                ]
            ]
            [ text model.id ]
        ]
    }
