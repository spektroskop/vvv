module Theme exposing (..)


type alias Theme =
    { body : List String
    , header : List String
    , navigation :
        { normal : List String
        , active : List String
        , background : List String
        }
    , docs :
        { highlight : List String
        , navigation : List String
        , active : List String
        }
    }


default : Theme
default =
    { body =
        [ "bg-zinc-100 text-stone-800"
        , "dark:bg-zinc-900 dark:text-stone-200"
        ]
    , header =
        [ "text-stone-200 bg-zinc-900"
        , "dark:text-stone-200 dark:bg-zinc-800"
        ]
    , navigation =
        { normal = []
        , active =
            [ "text-stone-800 text-shadow-white"
            , "bg-gradient-to-b"
            , "from-gray-300 to-gray-400"
            , "dark:from-gray-300 dark:to-gray-400"
            ]
        , background =
            [ "text-stone-900"
            , "bg-gradient-to-b"
            , "from-gray-300 to-gray-400"
            , "opacity-60"
            ]
        }
    , docs =
        { highlight = [ "bg-amber-300 dark:bg-amber-700" ]
        , navigation = 
            [ "text-zinc-700"
            , "bg-gradient-to-b from-zinc-300 to-zinc-400"
            ]
        , active = 
            [ "text-zinc-50 text-shadow"
            , "bg-gradient-to-b from-zinc-400 to-zinc-500"
            ]
        }
    }
