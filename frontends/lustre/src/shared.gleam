import loadable.{Loadable}
import lustre/attribute.{class, href, target}
import lustre/cmd.{Cmd}
import lustre/element.{Element, a, div, header, nav, span, text}
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
  let overview =
    a(
      [href("/overview"), class("flex items-center px-1")],
      [
        span(
          [
            class("flex items-center gap-1 rounded px-3 py-1"),
            class("text-stone-800 text-shadow-white"),
            class("bg-gradient-to-b"),
            class("from-gray-300 to-gray-400"),
            class("dark:from-gray-300 dark:to-gray-400"),
          ],
          [text("Overview")],
        ),
      ],
    )

  let docs =
    a(
      [href("/docs"), class("flex items-center px-1")],
      [
        span(
          [class("flex items-center gap-1 rounded px-3 py-1")],
          [text("Docs")],
        ),
      ],
    )

  let project =
    a(
      [
        href("https://github.com/spektroskop/vvv"),
        target("_blank"),
        class("flex items-center px-1"),
        class("hover:underline"),
      ],
      [span([], [text("vvv")])],
    )

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
          div([class("flex basis-3/6 justify-start")], [overview, docs]),
          div([class("flex shrink-0")], []),
          div([class("flex basis-3/6 justify-end")], [project]),
        ],
      ),
    ],
  )
}
