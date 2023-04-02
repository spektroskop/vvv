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
import Html exposing (Html, a, button, div, header, nav, span, text)
import Html.Attributes exposing (href, target)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Lib.Basics exposing (flip)
import Lib.Cmd as Cmd
import Lib.Decode as Decode
import Lib.Html as Html exposing (class)
import Lib.Html.Builder as Html
import Lib.Icon.Mini as Mini
import Lib.List as List
import Lib.Loadable as Loadable exposing (Loadable(..), Status(..))
import Lib.Return as Return
import Ports
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
    , reloadBrowser : Bool
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
        |> Decode.required "reload_browser" Decode.bool


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

                newModel =
                    { model
                        | app = Loaded Resolved app
                        , diff = Maybe.withDefault model.diff diff
                    }
            in
            case ( diff, app.reloadBrowser ) of
                ( Nothing, _ ) ->
                    ( newModel, scheduleApp (Just app) )

                ( Just [], _ ) ->
                    ( newModel, scheduleApp (Just app) )

                ( Just changes, False ) ->
                    ( newModel
                    , Cmd.batch
                        [ scheduleApp (Just app)
                        , List.map Static.toString changes
                            |> Encode.list Encode.string
                            |> Ports.Log
                            |> Ports.send
                        ]
                    )

                ( Just _, True ) ->
                    ( { newModel | diff = [] }
                    , Navigation.reloadAndSkipCache
                    )

        ReloadPage ->
            ( model, Navigation.reloadAndSkipCache )


scheduleApp : Maybe App -> Cmd Msg
scheduleApp app =
    Maybe.map .interval app
        |> Maybe.withDefault 5000
        |> max 1000
        |> flip Cmd.after GetApp


document : Maybe Route -> Model -> Browser.Document Msg
document route model =
    { title = "vvv"
    , body =
        let
            link_ target =
                Html.new a
                    |> Html.classes [ "flex items-center px-1" ]
                    |> Html.attributes [ Route.href target ]

            label_ body =
                Html.new span
                    |> Html.classes [ "flex items-center gap-1 rounded px-3 py-1" ]
                    |> Html.body body

            active_ target name =
                link_ target
                    |> Html.wrap (label_ name)
                    |> Html.classes
                        [ "text-white bg-cyan-900 text-shadow"
                        , "bg-gradient-to-b from-cyan-700 to-cyan-800"
                        ]
                    |> Html.build

            background_ target name =
                link_ target
                    |> Html.wrap (label_ name)
                    |> Html.classes
                        [ "text-white bg-neutral-600 text-shadow"
                        , "bg-gradient-to-b from-neutral-500 to-neutral-600"
                        ]
                    |> Html.build

            normal_ target name =
                link_ target
                    |> Html.classes [ "hover:underline" ]
                    |> Html.wrap (label_ name)
                    |> Html.build
        in
        [ header
            [ class
                [ "flex justify-center items-stretch sticky top-0 z-50"
                , "font-semibold h-[50px] shadow-md px-6 text-slate-800"
                , "bg-gradient-to-t from-stone-200 to-white"
                ]
            ]
            [ nav [ class [ "flex max-w-[var(--nav-width)] w-full" ] ]
                [ div [ class [ "flex basis-3/6" ] ]
                    [ case route of
                        Just Route.Overview ->
                            active_ Route.Overview [ text "Overview" ]

                        Just (Route.Detail _) ->
                            background_ Route.Overview [ text "Overview" ]

                        _ ->
                            normal_ Route.Overview [ text "Overview" ]
                    , case route of
                        Just (Route.Docs _) ->
                            active_ (Route.Docs Nothing) [ text "Docs" ]

                        _ ->
                            normal_ (Route.Docs Nothing) [ text "Docs" ]
                    ]
                , if model.diff == [] then
                    Html.none

                  else
                    div [ class [ "flex shrink-0" ] ]
                        [ button [ onClick ReloadPage ]
                            [ label_ [ text "A new version is available!" ]
                                |> Html.classes
                                    [ "bg-gradient-to-b from-green-700 to-green-800"
                                    , "text-white text-shadow"
                                    ]
                                |> Html.build
                            ]
                        ]
                , div [ class [ "flex basis-3/6 justify-end" ] ]
                    [ a
                        [ class [ "flex items-center px-1 hover:underline" ]
                        , href "https://github.com/spektroskop/vvv"
                        , target "_blank"
                        ]
                        [ label_ [ text "vvv", Mini.arrowTopRightOnSquare "w-5 h-5" ]
                            |> Html.build
                        ]
                    ]
                ]
            ]
        ]
    }
