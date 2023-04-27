import gleam/bit_builder.{BitBuilder}

pub external fn gzip(data: BitBuilder) -> BitBuilder =
  "zlib" "gzip"

pub fn return(a: fn(a) -> b, body: fn() -> a) -> b {
  a(body())
}

pub fn return2(a: fn(b) -> c, b: fn(a) -> b, body: fn() -> a) -> c {
  a(b(body()))
}
