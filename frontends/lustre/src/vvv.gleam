import gleam/option
import lustre
import lustre/attribute.{class}
import lustre/cmd
import lustre/element.{div}
import pages
import route
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

fn update(model: Model, msg: Msg) {
  case msg {
    SharedMsg(shared_msg) -> {
      let #(shared, shared_cmd) = shared.update(model.shared, shared_msg)
      #(Model(..model, shared: shared), cmd.map(shared_cmd, SharedMsg))
    }

    PageMsg(page_msg) -> {
      let #(page, page_cmd) = pages.update(model.page, page_msg)
      #(Model(..model, page: page), cmd.map(page_cmd, PageMsg))
    }
  }
}

fn render(model: Model) {
  div(
    [class("flex flex-col")],
    [
      shared.render(model.shared, option.Some(route.Overview))
      |> element.map(SharedMsg),
      pages.render(model.page)
      |> element.map(PageMsg),
    ],
  )
}
