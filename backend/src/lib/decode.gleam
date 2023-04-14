import gleam/dynamic.{Dynamic}
import gleam/map.{Map}
import gleam/result
import gleam/string

pub external fn toml(data: String) -> Result(Dynamic, Dynamic) =
  "tomerl" "parse"

pub fn shallow_map(
  of key_type: dynamic.Decoder(a),
) -> dynamic.Decoder(Map(a, Dynamic)) {
  dynamic.map(of: key_type, to: dynamic.dynamic)
}

pub fn non_empty_string(data: Dynamic) -> Result(String, dynamic.DecodeErrors) {
  use value <- result.then(
    dynamic.string(data)
    |> result.map(string.trim),
  )

  case value {
    "" ->
      Error([
        dynamic.DecodeError(
          expected: "non-empty string",
          found: "empty string",
          path: [],
        ),
      ])

    value -> Ok(value)
  }
}

pub fn singleton_list(
  of decoder: dynamic.Decoder(a),
) -> dynamic.Decoder(List(a)) {
  dynamic.decode1(fn(v) { [v] }, decoder)
}

// TODO: better name
pub fn to_list(of decoder: dynamic.Decoder(a)) -> dynamic.Decoder(List(a)) {
  dynamic.any([singleton_list(decoder), dynamic.list(decoder)])
}
