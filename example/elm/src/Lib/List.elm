module Lib.List exposing (toMaybe)


toMaybe : List a -> Maybe (List a)
toMaybe a =
    case a of
        [] ->
            Nothing

        v ->
            Just v
