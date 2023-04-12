import gleam/option.{Option}
import icon
import lib
import loadable.{Loadable}
import lustre/attribute.{class, href, target}
import lustre/cmd.{Cmd}
import lustre/element.{Element, a, button, div, header, nav, span, text}
import lustre/event
import route.{Route}
import static

pub type Msg {
  Reload
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

type Item(msg) =
  fn(String, List(Element(msg))) -> Element(msg)

type State(msg) {
  State(overview: Item(msg), docs: Item(msg))
}

pub fn render(_model: Model, route: Option(Route)) -> Element(Msg) {
  let State(overview, docs) = case route {
    option.Some(route.Overview) -> State(overview: active, docs: normal)
    option.Some(route.Detail(_)) -> State(overview: background, docs: normal)
    option.Some(route.Docs(_)) -> State(overview: normal, docs: active)
    option.None -> State(overview: normal, docs: normal)
  }

  let overview = overview("/overview", [text("Overview")])
  let docs = docs("/docs", [text("Docs")])

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
          div([class("flex shrink-0")], [refresh(["asdf"])]),
          div([class("flex basis-3/6 justify-end")], [project()]),
        ],
      ),
    ],
  )
}

fn link() -> lib.Builder(msg) {
  lib.new_builder(a)
  |> lib.classes(["flex items-center px-1"])
}

fn label() -> lib.Builder(msg) {
  lib.new_builder(span)
  |> lib.classes(["flex items-center gap-1 rounded px-3 py-1"])
}

fn active(target: String, body: List(Element(msg))) -> Element(msg) {
  link()
  |> lib.attributes([href(target)])
  |> lib.wrap(label())
  |> lib.classes([
    "text-stone-800 text-shadow-white", "bg-gradient-to-b",
    "from-gray-300 to-gray-400", "dark:from-gray-300 dark:to-gray-400",
  ])
  |> lib.body(body)
  |> lib.build()
}

fn background(target: String, body: List(Element(msg))) -> Element(msg) {
  link()
  |> lib.attributes([href(target)])
  |> lib.wrap(label())
  |> lib.classes([
    "text-stone-900", "bg-gradient-to-b", "from-gray-300 to-gray-400",
  ])
  |> lib.body(body)
  |> lib.build()
}

fn normal(target: String, body: List(Element(msg))) -> Element(msg) {
  link()
  |> lib.attributes([href(target)])
  |> lib.wrap(label())
  |> lib.classes([])
  |> lib.body(body)
  |> lib.build()
}

fn refresh(diff: List(_)) -> Element(Msg) {
  case diff {
    [] -> text("")

    _diff ->
      lib.new_builder(button)
      |> lib.attributes([event.on_click(Reload)])
      |> lib.wrap(label())
      |> lib.classes([
        "text-white text-shadow",
        "bg-gradient-to-b from-emerald-600 to-emerald-700",
      ])
      |> lib.body([text("A new version is available!")])
      |> lib.build
  }
}

fn project() -> Element(msg) {
  link()
  |> lib.classes(["hover:underline"])
  |> lib.attributes([
    href("https://github.com/spektroskop/vvv"),
    target("_blank"),
  ])
  |> lib.wrap(label())
  |> lib.body([
    text("vvv"),
    icon.arrow_top_right_on_square("w-5 h-5 translate-y-px"),
  ])
  |> lib.build()
}
