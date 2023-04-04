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
onRouteChange _ model =
    ( model, Cmd.none )


init : Navigation.Key -> ( Model, Cmd Msg )
init _ =
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
subscriptions _ =
    Sub.none


update : Msg -> Navigation.Key -> Model -> ( Model, Cmd Msg )
update msg _ model =
    case msg of
        GetApp ->
            getApp model

        GotApp (Err error) ->
            ( { model | app = Loadable.fail error model.app }
            , schedule (Loadable.value model.app)
            )

        GotApp (Ok app) ->
            let
                diff =
                    Loadable.value model.app
                        |> Maybe.map .assets
                        |> Maybe.map (Static.diff app.assets)
                        |> Maybe.andThen List.toMaybe

                updated =
                    { model
                        | app = Loadable.succeed app
                        , diff = Maybe.withDefault model.diff diff
                    }
            in
            case ( diff, app.reloadBrowser ) of
                ( Nothing, _ ) ->
                    ( updated, schedule (Just app) )

                ( Just [], _ ) ->
                    ( updated, schedule (Just app) )

                ( Just changes, False ) ->
                    ( updated
                    , Cmd.batch
                        [ schedule (Just app)
                        , List.map Static.toString changes
                            |> Encode.list Encode.string
                            |> Ports.Log
                            |> Ports.send
                        ]
                    )

                ( Just _, True ) ->
                    ( { updated | diff = [] }
                    , Navigation.reloadAndSkipCache
                    )

        ReloadPage ->
            ( model, Navigation.reloadAndSkipCache )


schedule : Maybe App -> Cmd Msg
schedule app =
    Maybe.map .interval app
        |> Maybe.withDefault 5000
        |> max 1000
        |> flip Cmd.after GetApp


document : Maybe Route -> Model -> Browser.Document Msg
document route model =
    { title = "vvv"
    , body =
        let
            { overview, docs } =
                case route of
                    Just Route.Overview ->
                        { overview = active, docs = normal }

                    Just (Route.Detail _) ->
                        { overview = background, docs = normal }

                    Just (Route.Docs _) ->
                        { overview = normal, docs = active }

                    _ ->
                        { overview = normal, docs = normal }

            pages =
                [ overview Route.Overview [ text "Overview" ]
                , docs (Route.Docs Nothing) [ text "Docs" ]
                ]
        in
        [ header
            [ class
                [ "flex justify-center items-stretch sticky top-0 px-6"
                , "h-[var(--header-height)] z-[var(--header-z)]"
                , "shadow-md font-semibold text-cyan-950"
                , "bg-gradient-to-t from-stone-200 to-white"
                ]
            ]
            [ nav [ class [ "flex max-w-[var(--nav-width)] w-full" ] ]
                [ div [ class [ "flex basis-3/6 justify-start" ] ] pages
                , div [ class [ "flex shrink-0" ] ] [ refresh model.diff ]
                , div [ class [ "flex basis-3/6 justify-end" ] ] [ project ]
                ]
            ]
        ]
    }


link : Html.Builder msg
link =
    Html.new a
        |> Html.classes [ "flex items-center px-1" ]


label : Html.Builder msg
label =
    Html.new span
        |> Html.classes [ "flex items-center gap-1 rounded px-3 py-1" ]


active : Route -> List (Html msg) -> Html msg
active target body =
    link
        |> Html.attributes [ Route.href target ]
        |> Html.wrap label
        |> Html.classes [ "text-white text-shadow" ]
        |> Html.classes [ "bg-gradient-to-b from-cyan-600 to-cyan-700" ]
        |> Html.body body
        |> Html.build


background : Route -> List (Html msg) -> Html msg
background target body =
    link
        |> Html.attributes [ Route.href target ]
        |> Html.wrap label
        |> Html.classes [ "text-white text-shadow" ]
        |> Html.classes [ "bg-gradient-to-b from-gray-400 to-gray-500" ]
        |> Html.body body
        |> Html.build


normal : Route -> List (Html msg) -> Html msg
normal target body =
    link
        |> Html.attributes [ Route.href target ]
        |> Html.classes [ "hover:underline" ]
        |> Html.wrap label
        |> Html.body body
        |> Html.build


refresh : List a -> Html Msg
refresh diff =
    if diff == [] then
        Html.none

    else
        Html.new button
            |> Html.attributes [ onClick ReloadPage ]
            |> Html.wrap label
            |> Html.classes [ "text-white text-shadow" ]
            |> Html.classes [ "bg-gradient-to-b from-teal-600 to-teal-700" ]
            |> Html.body [ text "A new version is available!" ]
            |> Html.build


project : Html msg
project =
    link
        |> Html.classes [ "hover:underline" ]
        |> Html.attributes [ href "https://github.com/spektroskop/vvv" ]
        |> Html.attributes [ target "_blank" ]
        |> Html.wrap label
        |> Html.body [ text "vvv" ]
        |> Html.body [ Mini.arrowTopRightOnSquare [ "w-5 h-5 translate-y-px" ] ]
        |> Html.build
