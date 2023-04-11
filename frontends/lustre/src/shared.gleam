import loadable.{Loadable}
import lustre/attribute.{class}
import lustre/cmd.{Cmd}
import lustre/element.{Element, div, text}
import static

pub type Msg {
  Noop
}

pub type App {
  App(interval: Int, assets: static.Assets, reload_browser: Bool)
}

pub type Model {
  Model(app: Loadable(App, String))
}

pub fn init() -> #(Model, Cmd(Msg)) {
  #(Model(app: loadable.Initial), cmd.none())
}

pub fn update(model, _msg) {
  #(model, cmd.none())
}

pub fn render(_model: Model) -> Element(Msg) {
  div([class("p-1 px-2 bg-pink-400")], [text("Shared")])
}
