module Lib.Cmd exposing (after)

import Process
import Task


after : Float -> msg -> Cmd msg
after sleep msg =
    Process.sleep sleep
        |> Task.perform (always msg)
