module Lib.Loadable exposing
    ( Loadable(..)
    , Status(..)
    , reload
    , value
    )


type Status
    = Resolved
    | Reloading


type Loadable e a
    = Initial
    | Loading
    | LoadingSlowly
    | Loaded Status a
    | Failed Status e (Maybe a)


value : Loadable e a -> Maybe a
value l =
    case l of
        Initial ->
            Nothing

        Loading ->
            Nothing

        LoadingSlowly ->
            Nothing

        Loaded _ a ->
            Just a

        Failed _ _ a ->
            a


reload : Loadable e a -> Loadable e a
reload l =
    case l of
        Initial ->
            Loading

        Loading ->
            Loading

        LoadingSlowly ->
            LoadingSlowly

        Loaded _ a ->
            Loaded Reloading a

        Failed _ e a ->
            Failed Reloading e a
