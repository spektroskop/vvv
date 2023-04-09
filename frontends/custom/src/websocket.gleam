import gleam/dynamic.{Dynamic}

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

pub fn connect(path: String, callback: fn(Event) -> a) {
  glue_connect(
    path,
    open: fn(conn) {
      Open(conn)
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
}
