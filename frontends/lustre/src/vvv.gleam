import lustre
import lustre/attribute.{class}
import lustre/cmd
import lustre/element.{div}
import pages
import shared

pub type Msg {
  SharedMsg(shared.Msg)
  PageMsg(pages.Msg)
}

pub type Model {
  Model(shared: shared.Model, page: pages.Model)
}

pub fn main() {
  let #(shared, shared_cmd) = shared.init()
  let #(page, page_cmd) = pages.init()
  let #(model, cmd) = #(
    Model(shared: shared, page: page),
    cmd.batch([cmd.map(shared_cmd, SharedMsg), cmd.map(page_cmd, PageMsg)]),
  )

  let app = lustre.application(#(model, cmd), update, render)
  lustre.start(app, "#app")
}

fn update(state, msg) {
  case msg {
    SharedMsg(_) -> #(state, cmd.none())
    PageMsg(_) -> #(state, cmd.none())
  }
}

fn render(model: Model) {
  div(
    [class("inline-flex gap-2")],
    [
      shared.render(model.shared)
      |> element.map(SharedMsg),
      pages.render(model.page)
      |> element.map(PageMsg),
    ],
  )
}
