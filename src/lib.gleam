import gleam/bit_builder.{BitBuilder}
import gleam/list
import gleam/result
import gleam/string

pub fn fields(string: String, separated_by sep: String) -> List(String) {
  string.split(string, sep)
  |> list.map(string.trim)
  |> list.filter(fn(part) { !string.is_empty(part) })
}

pub fn wrap(wrap: fn(a) -> b, make: fn() -> a) -> b {
  wrap(make())
}

pub fn unwrap_error(result: Result(a, e), or default: fn(e) -> a) -> a {
  case result {
    Ok(ok) -> ok
    Error(error) -> default(error)
  }
}

pub fn else(value: a, wrap: fn() -> Result(a, e)) -> a {
  result.unwrap(wrap(), value)
}

pub fn else_error(value: fn(e) -> a, wrap: fn() -> Result(a, e)) -> a {
  unwrap_error(wrap(), value)
}

pub fn guard(
  when predicate: Bool,
  return alternative: a,
  otherwise consequence: fn() -> a,
) -> a {
  case predicate {
    True -> alternative
    False -> consequence()
  }
}

pub fn when(
  predicate: Bool,
  consequence: fn() -> Result(a, Nil),
) -> Result(a, Nil) {
  case predicate {
    True -> consequence()
    False -> Error(Nil)
  }
}

pub external fn gzip(data: BitBuilder) -> BitBuilder =
  "zlib" "gzip"
