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
    |> result.replace_error([
      dynamic.DecodeError(
        expected: "string",
        found: dynamic.classify(data),
        path: [],
      ),
    ]),
  )

  case string.trim(value) {
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