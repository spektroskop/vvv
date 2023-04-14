import gleam/io
import websocket

pub fn main() {
  websocket.connect("/ws", io.debug)
  |> io.debug()
}
