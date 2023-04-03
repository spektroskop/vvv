module Page.Docs exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser


type Msg
    = Noop


type alias Model =
    {}


init : Maybe String -> ( Model, Cmd Msg )
init _ =
    ( {}, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )


document : Model -> Browser.Document Msg
document _ =
    { title = "Docs"
    , body = []
    }
