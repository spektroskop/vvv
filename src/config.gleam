import gleam/dynamic.{Dynamic}
import gleam/erlang/file
import gleam/erlang/os
import gleam/int
import gleam/list
import gleam/map.{Map}
import gleam/option.{Option}
import gleam/result
import gleam/string
import lib/decode

pub type Error {
  UnknownKeys(List(String))
  BadSection(String)
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

fn section(map: Map(String, Dynamic), name: String) -> Dynamic {
  case map.get(map, name) {
    Error(Nil) -> dynamic.from(map.new())
    Ok(value) -> value
  }
}

fn get_env(path: List(String)) -> Result(String, Nil) {
  list.reverse(path)
  |> string.join("_")
  |> os.get_env()
}

fn config_decoder(env: List(String), data: Dynamic) {
  use config_map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.nil_error(),
  )

  use server <- result.then(server_decoder(
    ["SERVER", ..env],
    section(config_map, "server"),
  ))

  Ok(Config(
    server: server,
    assets: todo,
    gzip: todo,
    types: todo,
    reloader: todo,
  ))
}

fn server_decoder(env: List(String), data: Dynamic) -> Result(Server, Nil) {
  use server_map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.nil_error(),
  )

  use port <- result.then(case get_env(["PORT", ..env]) {
    Ok(value) -> int.parse(value)

    Error(Nil) ->
      case map.get(server_map, "port") {
        Ok(value) ->
          dynamic.int(value)
          |> result.nil_error()

        Error(Nil) -> Error(Nil)
      }
  })

  Ok(Server(port: port))
}
