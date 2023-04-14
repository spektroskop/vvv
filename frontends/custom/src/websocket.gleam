import gleam/dynamic.{Dynamic}
import gleam/function.{compose}
import gleam/io
import gleam/option
import gleam/result
import gleam/uri.{Uri}
import lib

pub external type Socket

pub type Event {
  Open(Socket)
  Error(Dynamic)
  Message(String)
  Close(CloseReason)
}

pub type CloseReason {
  Normal
  Other(Int)
}

type Events {
  Events(
    open: fn(Socket) -> Event,
    error: fn(Dynamic) -> Event,
    message: fn(String) -> Event,
    close: fn(Int) -> Event,
  )
}

external fn glue_connect(String, Events, fn(Event) -> a) -> Socket =
  "./glue.js" "connect"

pub external fn close(socket: Socket) -> Nil =
  "./glue.js" "close"

fn close_reason(code: Int) -> CloseReason {
  case code {
    1000 -> Normal
    other -> Other(other)
  }
}

pub fn connect(path: String, handle: fn(Event) -> a) -> Result(Socket, Nil) {
  use document_uri <- result.then(lib.document_uri())

  let scheme = case document_uri.scheme {
    option.Some("https") -> option.Some("wss")
    option.Some("http") -> option.Some("ws")
    option.Some(_) -> panic
    option.None -> option.Some("ws")
  }

  let events =
    Events(
      open: Open,
      error: Error,
      message: Message,
      close: compose(close_reason, Close),
    )

  Uri(..document_uri, path: path, scheme: scheme)
  |> uri.to_string()
  |> glue_connect(events, handle)
  |> Ok
}
