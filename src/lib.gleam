import gleam/bit_builder.{BitBuilder}
import gleam/erlang/charlist.{Charlist}
import gleam/list
import gleam/result

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

pub fn wrap(wrap: fn(a) -> b, make: fn() -> a) -> b {
  wrap(make())
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

pub external fn basename(name: String) -> String =
  "filename" "basename"

pub external fn is_directory(path: String) -> Bool =
  "filelib" "is_dir"

pub external fn join(List(String)) -> String =
  "filename" "join"

pub external fn extension(String) -> String =
  "filename" "extension"

pub fn wildcard(from cwd: String, find pattern: String) -> List(String) {
  charlist.from_string(pattern)
  |> erlang_wildcard(charlist.from_string(cwd))
  |> list.map(charlist.to_string)
}

external fn erlang_wildcard(Charlist, Charlist) -> List(Charlist) =
  "filelib" "wildcard"

pub external fn gzip(data: BitBuilder) -> BitBuilder =
  "zlib" "gzip"
