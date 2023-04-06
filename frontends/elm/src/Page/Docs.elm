module Page.Docs exposing
    ( Model
    , Msg
    , document
    , init
    , subscriptions
    , update
    )

import Browser
import Browser.Dom as Dom
import Html exposing (Html, a, div, h1, p, section, text)
import Html.Attributes exposing (href, id)
import Lib.Html exposing (class)
import Task


type Msg
    = DomResult (Result Dom.Error ())


type alias Model =
    {}


init : Maybe String -> ( Model, Cmd Msg )
init fragment =
    ( {}
    , case fragment of
        Nothing ->
            Dom.setViewport 0 0
                |> Task.attempt DomResult

        Just id ->
            Dom.getElement id
                |> Task.andThen (\{ element } -> Dom.setViewport 0 (element.y - 100))
                |> Task.attempt DomResult
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DomResult _ ->
            ( model, Cmd.none )


document : Model -> Browser.Document Msg
document _ =
    { title = "Docs"
    , body =
        [ div [ class [ "flex justify-center" ] ]
            [ div
                [ class
                    [ "flex flex-col justify-center mt-10 gap-2"
                    , "max-w-[--nav-width] w-full"
                    ]
                ]
                [ part "Part1"
                , part "Part2"
                , part "Part3"
                ]
            ]
        ]
    }


part : String -> Html msg
part name =
    let
        sectionId =
            String.toLower name
    in
    section [ class [ "mb-10" ] ]
        [ a [ href ("#" ++ sectionId), class [ "hover:underline" ] ]
            [ h1 [ id sectionId, class [ "font-bold text-2xl mb-5 text-shadow" ] ]
                [ text name ]
            ]
        , p [ class [ "mb-5" ] ] [ text "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed vitae velit eget dolor cursus laoreet eu eget ligula. Integer at scelerisque mauris. Nam malesuada convallis nisi id porta. Aliquam pretium malesuada rutrum. Donec interdum nulla quam, vitae elementum diam imperdiet ut. Vestibulum at odio at mauris ornare condimentum. Nunc ac libero vel nisl iaculis condimentum." ]
        , p [ class [ "mb-5" ] ] [ text "Curabitur sit amet orci sem. Nunc cursus ante eu enim tempor dictum. Quisque viverra laoreet ipsum vitae facilisis. Vivamus orci nulla, tristique non lacinia sed, fringilla eget ante. Aenean nec orci turpis. Vivamus id pellentesque eros, ac lacinia libero. Phasellus euismod velit sit amet aliquam vulputate. Aliquam ac quam justo. Nulla in dictum arcu. Aenean non porta ligula. Cras non tortor accumsan, vulputate nibh nec, tincidunt nulla. Cras at nulla aliquam, tincidunt nisl ut, suscipit odio. Morbi dictum laoreet lacus, quis ultricies urna rhoncus nec. Suspendisse id neque mollis nisl condimentum aliquam. Mauris egestas, neque ac cursus scelerisque, sapien arcu semper tellus, vestibulum euismod nibh purus eu ante." ]
        , p [ class [ "mb-5" ] ] [ text "Aenean commodo vitae eros ut imperdiet. Vivamus magna eros, vulputate at nisl a, condimentum elementum enim. Vivamus volutpat a libero vel venenatis. Nunc in mattis sem. Suspendisse sodales ligula odio, et efficitur elit facilisis eget. In malesuada, nulla id iaculis mattis, urna dolor sollicitudin nulla, in bibendum nibh leo et urna. Aliquam eleifend eros non varius pellentesque. Curabitur sed erat vel risus luctus congue. Pellentesque mauris ipsum, tincidunt tempus vehicula a, vestibulum id velit. In et elit vel massa luctus tempus in elementum magna. Morbi porttitor nibh quis nisl efficitur gravida." ]
        , p [ class [ "mb-5" ] ] [ text "Fusce enim leo, congue vel lectus a, iaculis consequat enim. Fusce venenatis metus est, at molestie eros efficitur ut. Duis at ante et sapien dictum gravida. Ut in ullamcorper neque, quis venenatis eros. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Maecenas porttitor dapibus turpis, at venenatis nunc vehicula porttitor. Cras urna massa, viverra ac pellentesque eu, pulvinar vitae mi. Proin nec nulla vitae orci eleifend consectetur. In hac habitasse platea dictumst. Quisque et aliquet erat. Vivamus cursus accumsan tincidunt." ]
        , p [ class [ "mb-5" ] ] [ text "Pellentesque finibus est ligula, ullamcorper efficitur tellus varius a. Pellentesque efficitur, nibh pretium vehicula pellentesque, enim ante convallis nibh, vel laoreet neque neque non eros. Quisque maximus condimentum urna quis auctor. Ut lobortis convallis neque. Nullam ex mi, aliquet a lacus in, congue lobortis nisi. Maecenas consequat eu ligula quis ultrices. Phasellus pellentesque metus quis tortor sodales, sed tincidunt nisi ultricies. Praesent et rhoncus nulla. Nulla non tincidunt eros, at laoreet arcu. Nam egestas risus est, non efficitur leo pharetra at. Cras in dolor laoreet, egestas nisl vel, maximus neque. Duis sollicitudin diam mauris, sit amet commodo libero accumsan sed. In ac porta velit. Maecenas rutrum maximus dolor vitae posuere. Quisque nibh elit, posuere sed nisi non, lobortis laoreet dui." ]
        ]
