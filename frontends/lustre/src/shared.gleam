import loadable.{Loadable}
import lustre/attribute.{class}
import lustre/cmd.{Cmd}
import lustre/element.{Element, div, header, nav, text}
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
  header(
    [
      class("flex justify-center items-stretch sticky top-0 px-6"),
      class("h-[--header-height] z-[--header-z] font-semibold"),
      class("text-stone-200 bg-zinc-900"),
      class("dark:text-stone-200 dark:bg-zinc-800"),
    ],
    [
      nav(
        [class("flex max-w-[--nav-width] w-full")],
        [
          div([class("flex basis-3/6 justify-start")], [text("start")]),
          div([class("flex shrink-0")], [text("middle")]),
          div([class("flex basis-3/6 justify-end")], [text("end")]),
        ],
      ),
    ],
  )
}
