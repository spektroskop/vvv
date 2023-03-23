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
