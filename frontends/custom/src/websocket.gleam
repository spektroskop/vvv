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

external fn glue_connect(
  String,
  open: fn(Socket) -> a,
  error: fn(Dynamic) -> a,
  message: fn(String) -> a,
  close: fn(Int) -> a,
) -> a =
  "./glue.js" "connect"

pub external fn close(socket: Socket) -> Nil =
  "./glue.js" "close"

fn close_reason(code: Int) -> CloseReason {
  case code {
    1000 -> Normal
    other -> Other(other)
  }
}

pub fn connect(path: String, callback: fn(Event) -> a) -> Result(a, Nil) {
  use document_uri <- result.then(lib.document_uri())
  let scheme = case document_uri.scheme {
    option.Some("https") -> option.Some("wss")
    option.Some("http") -> option.Some("ws")
    option.Some(_) -> panic
    option.None -> option.Some("ws")
  }

  Ok({
    glue_connect(
      Uri(..document_uri, path: path, scheme: scheme)
      |> uri.to_string(),
      open: fn(socket) {
        Open(socket)
        |> callback()
      },
      error: fn(error) {
        Error(error)
        |> callback()
      },
      message: fn(message) {
        Message(message)
        |> callback()
      },
      close: fn(code) {
        close_reason(code)
        |> Close
        |> callback()
      },
    )
  })
}
