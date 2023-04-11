import gleam/string
import lustre/attribute.{class}
import lustre/cmd.{Cmd}
import lustre/element.{Element, div, text}

pub type Msg {
  Noop
}

pub type Model {
  NotFound
  Top
}

pub fn init() -> #(Model, Cmd(Msg)) {
  #(Top, cmd.none())
}

pub fn render(model: Model) -> Element(Msg) {
  div([class("p-1 px-2 bg-cyan-400")], [text(string.inspect(model))])
}
