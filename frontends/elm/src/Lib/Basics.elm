module Lib.Basics exposing (flip)


flip : (a -> b -> c) -> b -> a -> c
flip f b a =
    f a b
