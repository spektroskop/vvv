import gleam/option.{Option}

pub type Route {
  Top
  Overview
  Detail(String)
  Docs(Option(String))
}
