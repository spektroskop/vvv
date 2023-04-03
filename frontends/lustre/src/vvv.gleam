import lustre
import lustre/element.{div, text}
import lustre/cmd

pub fn main() {
  let app = lustre.application(#(Nil, cmd.none()), update, render)
  lustre.start(app, "#app")
}

fn update(state, _) {
  #(state, cmd.none())
}

fn render(_) {
  div([], [text(":)")])
}
