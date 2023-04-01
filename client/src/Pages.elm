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
import Page.Example
import Page.Home
import Route exposing (Route)
import Shared


type Msg
    = HomeMsg Page.Home.Msg
    | ExampleMsg Page.Example.Msg


type Model
    = NotFound
    | Top
    | Home Page.Home.Model
    | Example Page.Example.Model


init : Navigation.Key -> Maybe Route -> Maybe Model -> ( Model, Cmd Msg )
init key route current =
    case ( route, current ) of
        ( Nothing, _ ) ->
            ( NotFound, Cmd.none )

        ( Just Route.Top, _ ) ->
            Page.Home.init
                |> Return.map Home HomeMsg

        ( Just Route.Example, _ ) ->
            Page.Example.init
                |> Return.map Example ExampleMsg


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

        Example pageModel ->
            Page.Example.subscriptions pageModel
                |> Sub.map ExampleMsg


toShared : Model -> Shared.Model -> ( Shared.Model, Cmd Shared.Msg )
toShared model shared =
    case model of
        NotFound ->
            ( shared, Cmd.none )

        Top ->
            ( shared, Cmd.none )

        Home _ ->
            ( shared, Cmd.none )

        Example _ ->
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

        Example _ ->
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

        ( Home _, _ ) ->
            ( model, Cmd.none )

        ( Example pageModel, ExampleMsg pageMsg ) ->
            Page.Example.update pageMsg pageModel
                |> Return.map Example ExampleMsg

        ( Example _, _ ) ->
            ( model, Cmd.none )


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

        Example pageModel ->
            Page.Example.document pageModel
                |> Document.map ExampleMsg
