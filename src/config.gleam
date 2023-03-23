import gleam/dynamic.{Dynamic}
import gleam/erlang/file
import gleam/erlang/os
import gleam/int
import gleam/list
import gleam/map.{Map}
import gleam/option.{Option}
import gleam/result
import gleam/string
import gleam/uri
import lib/decode

pub type Error {
  UnknownKeys(List(String))
  BadSection(String)
  BadProperty(String)
  MissingProperty(String)
}

pub type Config {
  Config(server: Server, static: Static, gzip: Gzip)
}

pub type Server {
  Server(port: Int)
}

pub type Static {
  Static(
    base: String,
    index: List(String),
    types: Map(String, String),
    reloader: Option(Reloader),
  )
}

pub type Reloader {
  Reloader(method: String, path: List(String))
}

pub type Gzip {
  Gzip(threshold: Int, types: List(String))
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

  use static <- result.then(static_decoder(
    ["STATIC", ..env],
    section(config_map, "static"),
  ))

  Ok(Config(server: server, static: static, gzip: todo))
}

fn server_decoder(env: List(String), data: Dynamic) -> Result(Server, Nil) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.nil_error(),
  )

  use port <- result.then(case get_env(["PORT", ..env]) {
    Ok(value) -> int.parse(value)

    Error(Nil) ->
      case map.get(map, "port") {
        Ok(value) ->
          dynamic.int(value)
          |> result.nil_error()

        Error(Nil) -> Error(Nil)
      }
  })

  Ok(Server(port: port))
}

fn static_decoder(env: List(String), data: Dynamic) -> Result(Static, Nil) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.nil_error(),
  )

  use base <- result.then(case get_env(["BASE", ..env]) {
    Ok(value) -> Ok(value)

    Error(Nil) ->
      case map.get(map, "base") {
        Ok(value) ->
          dynamic.string(value)
          |> result.nil_error()

        Error(Nil) -> Error(Nil)
      }
  })

  use index <- result.then(case get_env(["INDEX", ..env]) {
    Ok(value) -> Ok(uri.path_segments(value))

    Error(Nil) ->
      case map.get(map, "index") {
        Ok(value) -> {
          use path <- result.then(
            dynamic.string(value)
            |> result.nil_error(),
          )

          Ok(uri.path_segments(path))
        }

        Error(Nil) -> Error(Nil)
      }
  })

  Ok(Static(base: base, index: index, types: todo, reloader: todo))
}
