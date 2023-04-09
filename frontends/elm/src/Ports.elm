port module Ports exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


type alias Message =
    { name : String, value : Encode.Value }


type Error
    = DecodeError Decode.Error
    | UnknownName String


type Incoming
    = Anchor String


type Outgoing
    = Log Encode.Value


port outgoing : Message -> Cmd msg


port incoming : (Message -> msg) -> Sub msg


send : Outgoing -> Cmd msg
send out =
    case out of
        Log value ->
            outgoing { name = "Log", value = value }


receive : (Incoming -> msg) -> (Error -> msg) -> Sub msg
receive toMsg onError =
    let
        decode msg =
            case msg.name of
                "Anchor" ->
                    case Decode.decodeValue Decode.string msg.value of
                        Ok id ->
                            toMsg (Anchor id)

                        Err err ->
                            onError (DecodeError err)

                unknown ->
                    onError (UnknownName unknown)
    in
    incoming decode
