module Lib.Return exposing
    ( Return
    , andThen
    , map
    , mapCmd
    , mapModel
    )


type alias Return msg model =
    ( model, Cmd msg )


mapModel : (model -> a) -> Return msg model -> Return msg a
mapModel m ( model, command ) =
    ( m model, command )


mapCmd : (msg -> a) -> Return msg model -> Return a model
mapCmd m ( model, cmd ) =
    ( model, Cmd.map m cmd )


map : (model1 -> model2) -> (msg1 -> msg2) -> Return msg1 model1 -> Return msg2 model2
map mm mc =
    mapModel mm >> mapCmd mc


andThen : (model -> Return msg a) -> Return msg model -> Return msg a
andThen m ( model, cmd ) =
    let
        ( newModel, newCmd ) =
            m model
    in
    ( newModel
    , Cmd.batch [ cmd, newCmd ]
    )
