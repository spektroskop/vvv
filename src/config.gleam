import gleam/dynamic.{Dynamic}
import gleam/erlang/file
import gleam/erlang/os
import gleam/http
import gleam/int
import gleam/json.{Json}
import gleam/list
import gleam/map.{Map}
import gleam/option.{Option}
import gleam/pair
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
  Reloader(method: http.Method, path: List(String))
}

pub type Gzip {
  Gzip(threshold: Int, types: Set(String))
}

pub fn read(
  env_prefix env: List(String),
  from path: Option(String),
) -> Result(Config, Error) {
  use data <- result.then(case path {
    option.None -> Ok(dynamic.from(map.new()))

    option.Some(path) -> {
      use data <- result.then(
        file.read(path)
        |> result.map_error(FileError),
      )

      decode.toml(data)
      |> result.replace_error(DecodeError)
    }
  })

  config_decoder(env, data)
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
    map.get(map, "server")
    |> result.unwrap(dynamic.from(map.new())),
  ))

  use static <- result.then(static_decoder(
    ["STATIC", ..env],
    map.get(map, "static")
    |> result.unwrap(dynamic.from(map.new())),
  ))

  use gzip <- result.then(gzip_decoder(
    ["GZIP", ..env],
    map.get(map, "gzip")
    |> result.unwrap(dynamic.from(map.new())),
  ))

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
        Ok(value) ->
          dynamic.string(value)
          |> result.replace_error(BadConfig("index"))
          |> result.map(uri.path_segments)

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

  use reloader <- result.then(reloader_decoder(
    ["RELOADER", ..env],
    map.get(map, "reloader")
    |> result.unwrap(dynamic.from(map.new())),
  ))

  Ok(Static(base: base, index: index, types: types, reloader: reloader))
}

fn reloader_decoder(
  env: List(String),
  data: Dynamic,
) -> Result(Option(Reloader), Error) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> result.replace_error(BadSection("reloader")),
  )

  use method <- result.then(case get_env(["METHOD", ..env]) {
    Ok(value) ->
      http.parse_method(value)
      |> result.replace_error(BadConfig("method"))
      |> result.map(option.Some)

    Error(Nil) ->
      case map.get(map, "method") {
        Ok(value) -> {
          use method <- result.then(
            dynamic.string(value)
            |> result.replace_error(BadConfig("method")),
          )

          http.parse_method(method)
          |> result.replace_error(BadConfig("method"))
          |> result.map(option.Some)
        }

        Error(Nil) -> Ok(option.None)
      }
  })

  use path <- result.then(case get_env(["PATH", ..env]) {
    Ok(value) ->
      uri.path_segments(value)
      |> option.Some
      |> Ok

    Error(Nil) ->
      case map.get(map, "path") {
        Ok(value) ->
          dynamic.string(value)
          |> result.replace_error(BadConfig("path"))
          |> result.map(uri.path_segments)
          |> result.map(option.Some)

        Error(Nil) -> Ok(option.None)
      }
  })

  case method, path {
    option.None, option.None -> Ok(option.None)
    option.Some(method), option.Some(path) ->
      Ok(option.Some(Reloader(method: method, path: path)))

    option.None, option.Some(_) -> Error(MissingConfig("method"))
    option.Some(_), option.None -> Error(MissingConfig("path"))
  }
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
        Ok(value) ->
          value
          |> dynamic.list(dynamic.string)
          |> result.replace_error(BadConfig("types"))
          |> result.map(set.from_list)

        Error(Nil) -> Ok(set.new())
      }
  })

  Ok(Gzip(threshold: threshold, types: types))
}

pub fn encode(config: Config) -> Json {
  json.object([
    #("server", encode_server(config.server)),
    #("static", encode_static(config.static)),
    #("gzip", encode_gzip(config.gzip)),
  ])
}

fn encode_server(server: Server) -> Json {
  json.object([#("port", json.int(server.port))])
}

fn encode_static(static: Static) -> Json {
  json.object([
    #("base", json.string(static.base)),
    #("index", json.array(static.index, json.string)),
    #(
      "types",
      map.to_list(static.types)
      |> list.map(pair.map_second(_, json.string))
      |> json.object(),
    ),
    #("reloader", json.nullable(static.reloader, encode_reloader)),
  ])
}

fn encode_reloader(reloader: Reloader) -> Json {
  json.object([
    #(
      "method",
      http.method_to_string(reloader.method)
      |> json.string(),
    ),
    #("path", json.array(reloader.path, json.string)),
  ])
}

fn encode_gzip(gzip: Gzip) -> Json {
  json.object([
    #("threshold", json.int(gzip.threshold)),
    #(
      "types",
      set.to_list(gzip.types)
      |> json.array(json.string),
    ),
  ])
}
