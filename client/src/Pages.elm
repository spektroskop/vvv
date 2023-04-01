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
import Lib.Return as Return
import Page.Home
import Route exposing (Route)
import Shared


type Msg
    = HomeMsg Page.Home.Msg


type Model
    = NotFound
    | Top
    | Home Page.Home.Model


init : Navigation.Key -> Maybe Route -> Maybe Model -> ( Model, Cmd Msg )
init key route current =
    case ( route, current ) of
        ( Nothing, _ ) ->
            ( NotFound, Cmd.none )

        ( Just Route.Top, _ ) ->
            Page.Home.init
                |> Return.map Home HomeMsg


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        NotFound ->
            Sub.none

        Top ->
            Sub.none

        Home pageModel ->
            Page.Home.subscriptions pageModel
                |> Sub.map HomeMsg


toShared : Model -> Shared.Model -> ( Shared.Model, Cmd Shared.Msg )
toShared model shared =
    case model of
        NotFound ->
            ( shared, Cmd.none )

        Top ->
            ( shared, Cmd.none )

        Home _ ->
            ( shared, Cmd.none )


fromShared : Shared.Model -> Model -> ( Model, Cmd Msg )
fromShared shared model =
    case model of
        NotFound ->
            ( model, Cmd.none )

        Top ->
            ( model, Cmd.none )

        Home _ ->
            ( model, Cmd.none )


update : Msg -> Navigation.Key -> Shared.Model -> Model -> ( Model, Cmd Msg )
update msg key shared model =
    case ( model, msg ) of
        ( NotFound, _ ) ->
            ( model, Cmd.none )

        ( Top, _ ) ->
            ( model, Cmd.none )

        ( Home pageModel, HomeMsg pageMsg ) ->
            Page.Home.update pageMsg pageModel
                |> Return.map Home HomeMsg


document : Model -> Browser.Document Msg
document model =
    case model of
        NotFound ->
            Document.placeholder "Not Found"

        Top ->
            Document.none

        Home pageModel ->
            Page.Home.document pageModel
                |> Document.map HomeMsg
