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
import Html exposing (div, h1, text)
import Lib.Document as Document
import Lib.Html exposing (class)
import Lib.Return as Return
import Page.Detail
import Page.Docs
import Page.Overview
import Route exposing (Route)
import Shared


type Msg
    = OverviewMsg Page.Overview.Msg
    | DetailMsg Page.Detail.Msg
    | DocsMsg Page.Docs.Msg


type Model
    = NotFound
    | Top
    | Overview Page.Overview.Model
    | Detail Page.Detail.Model
    | Docs Page.Docs.Model


init : Navigation.Key -> Maybe Route -> Maybe Model -> ( Model, Cmd Msg )
init key route current =
    case ( route, current ) of
        ( Nothing, _ ) ->
            ( NotFound, Cmd.none )

        ( Just Route.Top, _ ) ->
            ( Top, Route.replace key Route.Overview )

        ( Just Route.Overview, _ ) ->
            Page.Overview.init
                |> Return.map Overview OverviewMsg

        ( Just (Route.Detail id), _ ) ->
            Page.Detail.init id
                |> Return.map Detail DetailMsg

        ( Just (Route.Docs fragment), _ ) ->
            Page.Docs.init fragment
                |> Return.map Docs DocsMsg


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        NotFound ->
            Sub.none

        Top ->
            Sub.none

        Overview pageModel ->
            Page.Overview.subscriptions pageModel
                |> Sub.map OverviewMsg

        Detail pageModel ->
            Page.Detail.subscriptions pageModel
                |> Sub.map DetailMsg

        Docs pageModel ->
            Page.Docs.subscriptions pageModel
                |> Sub.map DocsMsg


toShared : Model -> Shared.Model -> ( Shared.Model, Cmd Shared.Msg )
toShared model shared =
    case model of
        NotFound ->
            ( shared, Cmd.none )

        Top ->
            ( shared, Cmd.none )

        Overview _ ->
            ( shared, Cmd.none )

        Detail _ ->
            ( shared, Cmd.none )

        Docs _ ->
            ( shared, Cmd.none )


fromShared : Shared.Model -> Model -> ( Model, Cmd Msg )
fromShared _ model =
    case model of
        NotFound ->
            ( model, Cmd.none )

        Top ->
            ( model, Cmd.none )

        Overview _ ->
            ( model, Cmd.none )

        Detail _ ->
            ( model, Cmd.none )

        Docs _ ->
            ( model, Cmd.none )


update : Msg -> Navigation.Key -> Shared.Model -> Model -> ( Model, Cmd Msg )
update msg _ _ model =
    case ( model, msg ) of
        ( NotFound, _ ) ->
            ( model, Cmd.none )

        ( Top, _ ) ->
            ( model, Cmd.none )

        ( Overview pageModel, OverviewMsg pageMsg ) ->
            Page.Overview.update pageMsg pageModel
                |> Return.map Overview OverviewMsg

        ( Overview _, _ ) ->
            ( model, Cmd.none )

        ( Detail pageModel, DetailMsg pageMsg ) ->
            Page.Detail.update pageMsg pageModel
                |> Return.map Detail DetailMsg

        ( Detail _, _ ) ->
            ( model, Cmd.none )

        ( Docs pageModel, DocsMsg pageMsg ) ->
            Page.Docs.update pageMsg pageModel
                |> Return.map Docs DocsMsg

        ( Docs _, _ ) ->
            ( model, Cmd.none )


document : Model -> Browser.Document Msg
document model =
    case model of
        NotFound ->
            { title = "Not Found"
            , body =
                [ div
                    [ class [ "flex justify-center mt-10" ] ]
                    [ h1 [ class [ "font-bold text-2xl mb-5" ] ]
                        [ text "Not Found" ]
                    ]
                ]
            }

        Top ->
            Document.none

        Overview pageModel ->
            Page.Overview.document pageModel
                |> Document.map OverviewMsg

        Detail pageModel ->
            Page.Detail.document pageModel
                |> Document.map DetailMsg

        Docs pageModel ->
            Page.Docs.document pageModel
                |> Document.map DocsMsg
