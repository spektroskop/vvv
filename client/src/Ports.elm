port module Ports exposing (..)

import Json.Encode as Encode


type alias Message =
    { name : String, value : Encode.Value }


type Outgoing
    = Log Encode.Value


port outgoing : Message -> Cmd msg


port incoming : (Message -> msg) -> Sub msg


send : Outgoing -> Cmd msg
send out =
    case out of
        Log value ->
            outgoing { name = "Log", value = value }
