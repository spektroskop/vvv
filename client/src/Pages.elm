module Pages exposing
    ( Model
    , Msg
    , document
    , fromShared
    , init
    , subscriptions
    , toShared
    , update
    )

import Browser
import Browser.Navigation as Navigation
import Lib.Document as Document
import Route exposing (Route)
import Shared


type Msg
    = Never


type Model
    = NotFound
    | Top


init : Navigation.Key -> Maybe Route -> Maybe Model -> ( Model, Cmd Msg )
init key route current =
    case ( route, current ) of
        ( Nothing, _ ) ->
            ( NotFound, Cmd.none )

        ( Just Route.Top, _ ) ->
            ( Top, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        NotFound ->
            Sub.none

        Top ->
            Sub.none


toShared : Model -> Shared.Model -> ( Shared.Model, Cmd Shared.Msg )
toShared model shared =
    case model of
        NotFound ->
            ( shared, Cmd.none )

        Top ->
            ( shared, Cmd.none )


fromShared : Shared.Model -> Model -> ( Model, Cmd Msg )
fromShared shared model =
    case model of
        NotFound ->
            ( model, Cmd.none )

        Top ->
            ( model, Cmd.none )


update : Msg -> Navigation.Key -> Shared.Model -> Model -> ( Model, Cmd Msg )
update msg key shared model =
    case ( model, msg ) of
        ( NotFound, _ ) ->
            ( model, Cmd.none )

        ( Top, _ ) ->
            ( model, Cmd.none )


document : Model -> Browser.Document Msg
document model =
    case model of
        NotFound ->
            Document.none

        Top ->
            Document.none