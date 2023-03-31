module Shared exposing
    ( Model
    , Msg
    , document
    , init
    , onRouteChange
    , subscriptions
    , update
    )

import Browser
import Browser.Navigation as Navigation
import Dict exposing (Dict)
import Html exposing (img)
import Html.Attributes exposing (src)
import Http
import Json.Decode as Decode
import Lib.Cmd as Cmd
import Lib.Html as Html exposing (class)
import Lib.Loadable as Loadable exposing (Loadable(..), Status(..))
import Lib.Return as Return
import Route exposing (Route)


type Msg
    = GetAssets
    | GotAssets (Result Http.Error (Dict String String))


type alias Model =
    { assets : Loadable Http.Error (Dict String String) }


onRouteChange : Maybe Route -> Model -> ( Model, Cmd Msg )
onRouteChange route model =
    ( model, Cmd.none )


init : Navigation.Key -> ( Model, Cmd Msg )
init key =
    ( { assets = Loading }, Cmd.none )
        |> Return.andThen getAssets


getAssets : Model -> ( Model, Cmd Msg )
getAssets model =
    ( { model | assets = Loadable.reload model.assets }
    , Http.get
        { url = "/api/assets"
        , expect =
            Http.expectJson GotAssets
                (Decode.dict Decode.string)
        }
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetAssets ->
            getAssets model

        GotAssets (Err error) ->
            let
                assets =
                    Loadable.value model.assets
            in
            ( { model | assets = Failed Resolved error assets }
            , Cmd.after 2500 GetAssets
            )

        GotAssets (Ok assets) ->
            ( { model | assets = Loaded Resolved assets }
            , Cmd.after 2500 GetAssets
            )


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
