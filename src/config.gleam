import gleam/dynamic
import gleam/erlang/file
import gleam/map.{Map}
import gleam/option.{Option}
import gleam/result
import lib/decode

pub type Error {
  BadCategory(String)
  BadProperty(String)
  MissingProperty(String)
}

pub type Config {
  Config(
    server: Server,
    assets: Assets,
    gzip: Gzip,
    types: Types,
    reloader: Option(Reloader),
  )
}

pub type Server {
  Server(port: Int)
}

pub type Assets {
  Assets(base_path: String, index_path: List(String))
}

pub type Gzip {
  Gzip(threshold: Int, types: List(String))
}

pub type Types =
  Map(String, String)

pub type Reloader {
  Reloader(method: String, path: List(String))
}

pub fn read(env: List(String), path: String) -> Result(Config, Nil) {
  use data <- result.then(
    file.read(path)
    |> result.nil_error(),
  )

  use decoded <- result.then(
    decode.toml(data)
    |> result.nil_error(),
  )

  config_decoder(env, decoded)
}

fn config_decoder(_env, data) {
  use _map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.nil_error(),
  )

  todo
}
