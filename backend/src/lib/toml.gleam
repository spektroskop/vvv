import gleam/dynamic.{Dynamic}

pub external fn decode(data: String) -> Result(Dynamic, Dynamic) =
  "tomerl" "parse"
