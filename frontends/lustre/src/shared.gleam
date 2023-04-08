import gleam/string
import loadable.{Loadable}
import lustre/element.{div, text}
import lustre/attribute.{class}
import static

pub type App {
  App(interval: Int, assets: static.Assets, reload_browser: Bool)
}

pub type Model {
  Model(app: Loadable(App, String))
}

pub fn new() -> Model {
  Model(app: loadable.Initial)
}

pub fn render(model: Model) {
  div(
    [class("inline-flex p-1 px-2 bg-rose-300")],
    [text(string.inspect(model))],
  )
}
