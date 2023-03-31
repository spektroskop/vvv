module Lib.Return exposing (Return, andThen)


type alias Return msg model =
    ( model, Cmd msg )


andThen : (model -> Return msg a) -> Return msg model -> Return msg a
andThen f ( model, cmd ) =
    let
        ( newModel, newCmd ) =
            f model
    in
    ( newModel
    , Cmd.batch [ cmd, newCmd ]
    )
