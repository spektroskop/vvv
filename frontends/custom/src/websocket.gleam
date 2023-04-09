pub external type Connection

pub type Event {
  Open(Connection)
  TextMessage(String)
  Close(Reason)
}

pub type Reason {
  Normal
  Other(Int)
}

type Handler(a) {
  Handler(
    on_open: fn(Connection) -> a,
    on_close: fn(Int) -> a,
    on_message: fn(String) -> a,
  )
}

external fn glue_connect(String, Handler(a)) -> a =
  "./glue.js" "connect"

fn handle(callback: fn(Event) -> a) -> Handler(a) {
  Handler(
    on_open: fn(conn) { callback(Open(conn)) },
    on_close: fn(code) {
      case code {
        1000 -> callback(Close(Normal))
        other -> callback(Close(Other(other)))
      }
    },
    on_message: fn(message) { callback(TextMessage(message)) },
  )
}

pub fn connect(path: String, handler: fn(Event) -> Nil) {
  glue_connect(path, handle(handler))
}
