import gleam/dynamic.{Dynamic}
import gleam/erlang/file
import gleam/erlang/os
import gleam/int
import gleam/list
import gleam/map.{Map}
import gleam/option.{Option}
import gleam/result
import gleam/set.{Set}
import gleam/string
import gleam/uri
import lib/decode

pub type Error {
  FileError(file.Reason)
  DecodeError
  UnknownKeys(List(String))
  BadSection(String)
  MissingConfig(String)
  BadConfig(String)
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
  Gzip(threshold: Int, types: Set(String))
}

pub fn read(env: List(String), path: String) -> Result(Config, Error) {
  use data <- result.then(
    file.read(path)
    |> result.map_error(FileError),
  )

  use decoded <- result.then(
    decode.toml(data)
    |> result.replace_error(DecodeError),
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

fn config_decoder(env: List(String), data: Dynamic) -> Result(Config, Error) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.replace_error(DecodeError),
  )

  use server <- result.then(server_decoder(
    ["SERVER", ..env],
    section(map, "server"),
  ))

  use static <- result.then(static_decoder(
    ["STATIC", ..env],
    section(map, "static"),
  ))

  use gzip <- result.then(gzip_decoder(["GZIP", ..env], section(map, "gzip")))

  Ok(Config(server: server, static: static, gzip: gzip))
}

fn server_decoder(env: List(String), data: Dynamic) -> Result(Server, Error) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.replace_error(BadSection("server")),
  )

  use port <- result.then(case get_env(["PORT", ..env]) {
    Ok(value) ->
      int.parse(value)
      |> result.replace_error(BadConfig("port"))

    Error(Nil) ->
      case map.get(map, "port") {
        Ok(value) ->
          dynamic.int(value)
          |> result.replace_error(BadConfig("port"))

        Error(Nil) -> Error(MissingConfig("port"))
      }
  })

  Ok(Server(port: port))
}

fn static_decoder(env: List(String), data: Dynamic) -> Result(Static, Error) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.replace_error(BadSection("server")),
  )

  use base <- result.then(case get_env(["BASE", ..env]) {
    Ok(value) -> Ok(value)

    Error(Nil) ->
      case map.get(map, "base") {
        Ok(value) ->
          dynamic.string(value)
          |> result.replace_error(BadConfig("base"))

        Error(Nil) -> Error(MissingConfig("base"))
      }
  })

  use index <- result.then(case get_env(["INDEX", ..env]) {
    Ok(value) -> Ok(uri.path_segments(value))

    Error(Nil) ->
      case map.get(map, "index") {
        Ok(value) -> {
          use path <- result.then(
            dynamic.string(value)
            |> result.replace_error(BadConfig("base")),
          )

          Ok(uri.path_segments(path))
        }

        Error(Nil) -> Ok(["index.html"])
      }
  })

  use types <- result.then(case get_env(["TYPES", ..env]) {
    Ok(value) -> {
      use args <- result.then(
        string.split(value, ",")
        |> list.try_map(fn(arg) {
          case string.split(arg, ":") {
            [ext, kind] -> Ok(#(ext, kind))
            _else -> Error(BadConfig("types"))
          }
        }),
      )

      Ok(map.from_list(args))
    }

    Error(Nil) ->
      case map.get(map, "types") {
        Ok(value) ->
          value
          |> dynamic.map(dynamic.string, dynamic.string)
          |> result.replace_error(BadConfig("types"))

        Error(Nil) -> Ok(map.new())
      }
  })

  Ok(Static(base: base, index: index, types: types, reloader: todo))
}

fn gzip_decoder(env: List(String), data: Dynamic) -> Result(Gzip, Error) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.replace_error(BadSection("gzip")),
  )

  use threshold <- result.then(case get_env(["THRESHOLD", ..env]) {
    Ok(value) ->
      int.parse(value)
      |> result.replace_error(BadConfig("threshold"))

    Error(Nil) ->
      case map.get(map, "port") {
        Ok(value) ->
          dynamic.int(value)
          |> result.replace_error(BadConfig("threshold"))

        Error(Nil) -> Ok(1000)
      }
  })

  use types <- result.then(case get_env(["TYPES", ..env]) {
    Ok(value) ->
      string.split(value, ",")
      |> set.from_list()
      |> Ok

    Error(Nil) ->
      case map.get(map, "types") {
        Ok(value) -> {
          use types <- result.then(
            value
            |> dynamic.list(dynamic.string)
            |> result.replace_error(BadConfig("types")),
          )

          Ok(set.from_list(types))
        }

        Error(Nil) -> Ok(set.new())
      }
  })

  Ok(Gzip(threshold: threshold, types: types))
}
