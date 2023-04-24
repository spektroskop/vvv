import gleam/dynamic.{DecodeErrors, Decoder, Dynamic}
import gleam/map.{Map}
import gleam/result
import lib/list as list_extra
import lib/string as string_extra

pub fn shallow_map(of key: Decoder(a)) -> Decoder(Map(a, Dynamic)) {
  dynamic.map(of: key, to: dynamic.dynamic)
}

pub fn into_list(of inner: Decoder(a)) -> Decoder(List(a)) {
  dynamic.decode1(list_extra.singleton, inner)
}

pub fn optional_list(of inner: Decoder(a)) -> Decoder(List(a)) {
  dynamic.any([dynamic.list(inner), into_list(inner)])
}

pub fn non_empty_string(data: Dynamic) -> Result(String, DecodeErrors) {
  use string <- result.then(dynamic.string(data))

  string_extra.to_non_empty(string)
  |> result.replace_error([
    dynamic.DecodeError(
      expected: "non-empty string",
      found: "empty string",
      path: [],
    ),
  ])
}
