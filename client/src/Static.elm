module Static exposing
    ( Assets
    , Diff(..)
    , decoder
    , diff
    , toString
    )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Set


type alias Assets =
    Dict String String


type Diff
    = Added String
    | Removed String
    | Changed String


decoder : Decoder Assets
decoder =
    Decode.dict Decode.string


diff : Assets -> Assets -> List Diff
diff static1 static2 =
    let
        keys1 =
            Dict.keys static1 |> Set.fromList

        keys2 =
            Dict.keys static2 |> Set.fromList

        compare key =
            Dict.get key static1 /= Dict.get key static2

        ( changedKeys, _ ) =
            Set.intersect keys1 keys2
                |> Set.partition compare
    in
    List.concat
        [ Set.diff keys1 keys2 |> Set.toList |> List.map Added
        , Set.diff keys2 keys1 |> Set.toList |> List.map Removed
        , changedKeys |> Set.toList |> List.map Changed
        ]


toString : Diff -> String
toString change =
    case change of
        Added name ->
            "Added: " ++ name

        Removed name ->
            "Removed: " ++ name

        Changed name ->
            "Changed: " ++ name
