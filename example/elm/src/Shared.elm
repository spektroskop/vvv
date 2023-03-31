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
import Html exposing (button, text)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Lib.Cmd as Cmd
import Lib.Html as Html exposing (class)
import Lib.List as List
import Lib.Loadable as Loadable exposing (Loadable(..), Status(..))
import Lib.Return as Return
import Route exposing (Route)
import Static


type Msg
    = GetAssets
    | GotAssets (Result Http.Error Static.Assets)
    | ReloadPage


type alias Model =
    { assets : Loadable Http.Error Static.Assets
    , diff : List Static.Diff
    }


onRouteChange : Maybe Route -> Model -> ( Model, Cmd Msg )
onRouteChange route model =
    ( model, Cmd.none )


init : Navigation.Key -> ( Model, Cmd Msg )
init key =
    ( initialModel, Cmd.none )
        |> Return.andThen getAssets


initialModel : Model
initialModel =
    { assets = Loading
    , diff = []
    }


getAssets : Model -> ( Model, Cmd Msg )
getAssets model =
    ( { model | assets = Loadable.reload model.assets }
    , Http.get
        { url = "/api/assets"
        , expect = Http.expectJson GotAssets Static.decoder
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
            let
                diff =
                    Loadable.value model.assets
                        |> Maybe.map (Static.diff assets)
                        |> Maybe.andThen List.toMaybe
            in
            ( { model
                | assets = Loaded Resolved assets
                , diff = Maybe.withDefault model.diff diff
              }
            , Cmd.after 2500 GetAssets
            )

        ReloadPage ->
            ( model
            , Navigation.reloadAndSkipCache
            )


document : Maybe Route -> Model -> Browser.Document Msg
document route model =
    { title = "Example"
    , body =
        [ if model.diff == [] then
            text "Example"

          else
            button
                [ onClick ReloadPage
                , class
                    [ "px-3 py-2 rounded"
                    , "bg-gray-300 text-gray-900"
                    ]
                ]
                [ text "A new version is available!" ]
        ]
    }
