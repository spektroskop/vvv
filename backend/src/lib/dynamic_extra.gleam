import gleam/dynamic.{Dynamic}
import gleam/map.{Map}
import gleam/result
import lib/string_extra

pub fn shallow_map(
  of key_type: dynamic.Decoder(a),
) -> dynamic.Decoder(Map(a, Dynamic)) {
  dynamic.map(of: key_type, to: dynamic.dynamic)
}

pub fn into_list(of decoder: dynamic.Decoder(a)) -> dynamic.Decoder(List(a)) {
  dynamic.decode1(fn(v) { [v] }, decoder)
}

pub fn optional_list(of decoder: dynamic.Decoder(a)) -> dynamic.Decoder(List(a)) {
  dynamic.any([dynamic.list(decoder), into_list(decoder)])
}

pub fn non_empty_string(data: Dynamic) -> Result(String, dynamic.DecodeErrors) {
  use string <- result.then(dynamic.string(data))

  string_extra.non_empty_string(string)
  |> result.replace_error([
    dynamic.DecodeError(
      expected: "non-empty string",
      found: "empty string",
      path: [],
    ),
  ])
}
