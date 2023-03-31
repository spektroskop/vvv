module Main exposing (main)

import Browser
import Browser.Navigation as Navigation
import Lib.Document as Document
import Pages
import Route exposing (Route)
import Shared
import Url exposing (Url)


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | SharedMsg Shared.Msg
    | PageMsg Pages.Msg


type alias Model =
    { key : Navigation.Key
    , route : Maybe Route
    , shared : Shared.Model
    , page : Pages.Model
    }


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


init : () -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init () url key =
    let
        route =
            Route.fromUrl url

        ( shared, sharedCmd ) =
            Shared.init key

        ( page, pageCmd ) =
            Pages.init key route Nothing
    in
    ( { key = key
      , route = route
      , shared = shared
      , page = page
      }
    , Cmd.batch
        [ Cmd.map SharedMsg sharedCmd
        , Cmd.map PageMsg pageCmd
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Shared.subscriptions model.shared
            |> Sub.map SharedMsg
        , Pages.subscriptions model.page
            |> Sub.map PageMsg
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested (Browser.Internal url) ->
            ( model
            , Url.toString url
                |> Navigation.pushUrl model.key
            )

        UrlRequested (Browser.External href) ->
            ( model
            , Navigation.load href
            )

        UrlChanged url ->
            let
                route =
                    Route.fromUrl url

                ( page, pageCmd ) =
                    Pages.init model.key route (Just model.page)
            in
            ( { model | route = route, page = page }
            , Cmd.map PageMsg pageCmd
            )

        SharedMsg sharedMsg ->
            let
                ( shared, sharedCmd ) =
                    Shared.update sharedMsg model.shared

                ( page, pageCmd ) =
                    Pages.fromShared shared model.page
            in
            ( { model | shared = shared, page = page }
            , Cmd.batch
                [ Cmd.map SharedMsg sharedCmd
                , Cmd.map PageMsg pageCmd
                ]
            )

        PageMsg pageMsg ->
            let
                ( page, pageCmd ) =
                    Pages.update pageMsg model.key model.shared model.page

                ( shared, sharedCmd ) =
                    Pages.toShared page model.shared
            in
            ( { model | shared = shared, page = page }
            , Cmd.batch
                [ Cmd.map SharedMsg sharedCmd
                , Cmd.map PageMsg pageCmd
                ]
            )


view : Model -> Browser.Document Msg
view model =
    Document.join " - "
        [ Shared.document model.route model.shared
            |> Document.map SharedMsg
        , Pages.document model.page
            |> Document.map PageMsg
        ]
