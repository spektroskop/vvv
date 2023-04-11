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

pub fn update(model, _msg) {
  #(model, cmd.none())
}

pub fn render(model: Model) -> Element(Msg) {
  div([class("")], [text(string.inspect(model))])
}
