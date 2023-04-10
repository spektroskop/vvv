import gleam/io
import websocket

pub fn main() {
  use event <- websocket.connect("/ws")
  io.debug(event)
  Nil
}
