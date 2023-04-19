import gleam/bit_builder.{BitBuilder}
import gleam/result
import gleam/string

pub fn return(a: fn(a) -> b, body: fn() -> a) -> b {
  a(body())
}

pub fn return2(a: fn(b) -> c, b: fn(a) -> b, body: fn() -> a) -> c {
  a(b(body()))
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
