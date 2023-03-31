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
import Html exposing (button, img, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder)
import Lib.Basics exposing (flip)
import Lib.Cmd as Cmd
import Lib.Decode as Decode
import Lib.Html as Html exposing (class)
import Lib.List as List
import Lib.Loadable as Loadable exposing (Loadable(..), Status(..))
import Lib.Return as Return
import Route exposing (Route)
import Static


type Msg
    = GetApp
    | GotApp (Result Http.Error App)
    | ReloadPage


type alias Model =
    { app : Loadable Http.Error App
    , diff : List Static.Diff
    }


type alias App =
    { interval : Float
    , assets : Static.Assets
    }


onRouteChange : Maybe Route -> Model -> ( Model, Cmd Msg )
onRouteChange route model =
    ( model, Cmd.none )


init : Navigation.Key -> ( Model, Cmd Msg )
init key =
    ( initialModel, Cmd.none )
        |> Return.andThen getApp


initialModel : Model
initialModel =
    { app = Loading
    , diff = []
    }


getApp : Model -> ( Model, Cmd Msg )
getApp model =
    ( { model | app = Loadable.reload model.app }
    , Http.get
        { url = "/api/app"
        , expect = Http.expectJson GotApp appDecoder
        }
    )


appDecoder : Decoder App
appDecoder =
    Decode.succeed App
        |> Decode.required "interval" Decode.float
        |> Decode.required "assets" Static.decoder


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetApp ->
            getApp model

        GotApp (Err error) ->
            let
                app =
                    Loadable.value model.app
            in
            ( { model | app = Failed Resolved error app }
            , scheduleApp app
            )

        GotApp (Ok app) ->
            let
                diff =
                    Loadable.value model.app
                        |> Maybe.map .assets
                        |> Maybe.map (Static.diff app.assets)
                        |> Maybe.andThen List.toMaybe
            in
            ( { model
                | app = Loaded Resolved app
                , diff = Maybe.withDefault model.diff diff
              }
            , scheduleApp (Just app)
            )

        ReloadPage ->
            ( model
            , Navigation.reloadAndSkipCache
            )


scheduleApp : Maybe App -> Cmd Msg
scheduleApp app =
    Maybe.map .interval app
        |> Maybe.withDefault 5000
        |> max 1000
        |> flip Cmd.after GetApp


document : Maybe Route -> Model -> Browser.Document Msg
document route model =
    { title = "Example"
    , body =
        [ if model.diff == [] then
            img [ src "/heart.svg", class [ "h-[50vh] w-[50vw]" ] ] []

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
