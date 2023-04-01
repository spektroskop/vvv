module Lib.Decode exposing
    ( andMap
    , default
    , optional
    , required
    )

import Json.Decode as Decode exposing (Decoder)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


required : String -> Decoder a -> Decoder (a -> b) -> Decoder b
required key value =
    Decode.field key value
        |> andMap


optional : String -> Decoder a -> Decoder (Maybe a -> b) -> Decoder b
optional key valueDecoder =
    let
        try maybe =
            case maybe of
                Nothing ->
                    Decode.succeed Nothing

                Just _ ->
                    Decode.field key valueDecoder
                        |> Decode.map Just
    in
    Decode.field key Decode.value
        |> Decode.maybe
        |> Decode.andThen try
        |> andMap


default : String -> Decoder a -> a -> Decoder (a -> b) -> Decoder b
default key valueDecoder defaultValue =
    let
        try maybe =
            case maybe of
                Nothing ->
                    Decode.succeed defaultValue

                Just _ ->
                    Decode.field key valueDecoder
    in
    Decode.field key Decode.value
        |> Decode.maybe
        |> Decode.andThen try
        |> andMap
