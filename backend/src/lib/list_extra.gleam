import gleam/option.{Option}

pub fn singleton(value: a) -> List(a) {
  [value]
}

pub fn to_option(list: List(a)) -> Option(List(a)) {
  case list {
    [] -> option.None
    list -> option.Some(list)
  }
}

pub fn to_result(list: List(a)) -> Result(List(a), Nil) {
  case list {
    [] -> Error(Nil)
    list -> Ok(list)
  }
}
