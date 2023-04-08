import gleam/string
import loadable.{Loadable}
import lustre/element.{div, text}
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
  div([], [text(string.inspect(model))])
}
