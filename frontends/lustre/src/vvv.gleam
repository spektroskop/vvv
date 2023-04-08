import lustre
import lustre/cmd
import shared

type Model {
  Model(shared: shared.Model)
}

pub fn main() {
  let model = Model(shared: shared.new())
  let app = lustre.application(#(model, cmd.none()), update, render)
  lustre.start(app, "#app")
}

fn update(state, _) {
  #(state, cmd.none())
}

fn render(model: Model) {
  shared.render(model.shared)
}
