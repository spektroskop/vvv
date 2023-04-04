module Lib.Loadable exposing
    ( Loadable(..)
    , Status(..)
    , fail
    , loadingSlowly
    , reload
    , succeed
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


succeed : a -> Loadable e a
succeed =
    Loaded Resolved


fail : e -> Loadable e a -> Loadable e a
fail e =
    Failed Resolved e << value


value : Loadable e a -> Maybe a
value l =
    case l of
        Loaded _ a ->
            Just a

        Failed _ _ a ->
            a

        _ ->
            Nothing


reload : Loadable e a -> Loadable e a
reload l =
    case l of
        LoadingSlowly ->
            LoadingSlowly

        Loaded _ a ->
            Loaded Reloading a

        Failed _ e a ->
            Failed Reloading e a

        _ ->
            Loading


loadingSlowly : Loadable e a -> Loadable e a
loadingSlowly l =
    case l of
        Loading ->
            LoadingSlowly

        other ->
            other
