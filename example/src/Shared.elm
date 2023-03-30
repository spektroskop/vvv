module Shared exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser
import Browser.Navigation as Navigation
import Html exposing (img)
import Html.Attributes exposing (src)
import Lib.Html as Html exposing (class)
import Route exposing (Route)


type Msg
    = Never


type alias Model =
    {}


init : Navigation.Key -> ( Model, Cmd Msg )
init key =
    ( {}, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


document : Maybe Route -> Model -> Browser.Document Msg
document route model =
    { title = "Example"
    , body =
        [ img
            [ src "/heart.svg"
            , class [ "h-[50vh] w-[50vh]" ]
            ]
            []
        ]
    }
