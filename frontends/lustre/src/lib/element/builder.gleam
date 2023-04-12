import gleam/list
import gleam/option.{Option}
import gleam/string
import lustre/attribute.{Attribute}
import lustre/element.{Element}

pub type Node(msg) =
  fn(List(Attribute(msg)), List(Element(msg))) -> Element(msg)

pub type Builder(msg) {
  Builder(
    node: Node(msg),
    attributes: List(Attribute(msg)),
    classes: List(String),
    body: List(Element(msg)),
    parent: Option(Builder(msg)),
  )
}

pub fn new(node: Node(msg)) -> Builder(msg) {
  Builder(
    node: node,
    attributes: [],
    classes: [],
    body: [],
    parent: option.None,
  )
}

pub fn attributes(b: Builder(msg), v: List(Attribute(msg))) -> Builder(msg) {
  Builder(..b, attributes: list.flatten([b.attributes, v]))
}

pub fn classes(b: Builder(msg), v: List(String)) -> Builder(msg) {
  Builder(..b, classes: list.flatten([b.classes, v]))
}

pub fn body(b: Builder(msg), v: List(Element(msg))) -> Builder(msg) {
  Builder(..b, body: list.flatten([b.body, v]))
}

pub fn wrap(p: Builder(msg), b: Builder(msg)) -> Builder(msg) {
  Builder(..b, parent: option.Some(p))
}

pub fn build(b: Builder(msg)) -> Element(msg) {
  let self =
    string.join(b.classes, with: " ")
    |> attribute.class()
    |> list.prepend(to: b.attributes)
    |> b.node(b.body)

  case b.parent {
    option.None -> self
    option.Some(v) ->
      v
      |> body([self])
      |> build()
  }
}
