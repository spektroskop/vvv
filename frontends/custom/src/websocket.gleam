import gleam/dynamic.{Dynamic}
import gleam/option
import gleam/uri.{Uri}
import gleam/result
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

type Callbacks(a) {
  Callbacks(
    open: fn(Socket) -> a,
    error: fn(Dynamic) -> a,
    message: fn(String) -> a,
    close: fn(Int) -> a,
  )
}

external fn glue_connect(String, callbacks: Callbacks(a)) -> a =
  "./glue.js" "connect"

pub external fn close(socket: Socket) -> Nil =
  "./glue.js" "close"

fn close_reason(code: Int) -> CloseReason {
  case code {
    1000 -> Normal
    other -> Other(other)
  }
}

pub fn connect(path: String, handle: fn(Event) -> a) -> Result(a, Nil) {
  use document_uri <- result.then(lib.document_uri())

  let scheme = case document_uri.scheme {
    option.Some("https") -> option.Some("wss")
    option.Some("http") -> option.Some("ws")
    option.Some(_) -> panic
    option.None -> option.Some("ws")
  }

  let callbacks =
    Callbacks(
      open: fn(socket) { handle(Open(socket)) },
      error: fn(error) { handle(Error(error)) },
      message: fn(message) { handle(Message(message)) },
      close: fn(code) { handle(Close(close_reason(code))) },
    )

  Uri(..document_uri, path: path, scheme: scheme)
  |> uri.to_string()
  |> glue_connect(callbacks)
  |> Ok
}
