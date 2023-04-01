module Page.Home exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser
import Html exposing (Html, img)
import Html.Attributes exposing (src)
import Lib.Html exposing (class)
import Lib.Return as Return exposing (Return)


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
    { title = "Home"
    , body =
        [ img
            [ src "/heart.svg"
            , class [ "h-[50vh] w-[50vw]" ]
            ]
            []
        ]
    }
