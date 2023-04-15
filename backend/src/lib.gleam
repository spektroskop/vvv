import gleam/bit_builder.{BitBuilder}
import gleam/result
import gleam/string

pub fn return(wrap: fn(a) -> b, body: fn() -> a) -> b {
  wrap(body())
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

pub fn string_to_result(string: String) -> Result(String, Nil) {
  case string {
    "" -> Error(Nil)
    _ -> Ok(string)
  }
}

pub fn string_to_non_empty_string(string: String) -> Result(String, Nil) {
  string.trim(string)
  |> string_to_result()
}
