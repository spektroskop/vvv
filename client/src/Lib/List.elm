module Lib.List exposing
    ( prepend
    , toMaybe
    )


toMaybe : List a -> Maybe (List a)
toMaybe a =
    case a of
        [] ->
            Nothing

        v ->
            Just v


prepend : List a -> a -> List a
prepend vs v =
    v :: vs
