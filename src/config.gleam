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
import lib/report.{Report}

pub type Error {
  FileError(reason: file.Reason)
  DecodeError
  UnknownKeys(keys: List(String))
  BadSection(name: String)
  MissingConfig(name: String)
  BadConfig(name: String, errors: dynamic.DecodeErrors)
}

pub fn read(env: List(String)) -> Result(Config, Report(Error)) {
  use data <- result.then({
    case get_env(["CONFIG", ..env]) {
      Error(Nil) -> Ok(dynamic.from(map.new()))

      Ok(path) -> {
        use data <- result.then(
          file.read(path)
          |> report.map_error(FileError),
        )

        decode.toml(data)
        |> report.replace_error(DecodeError)
      }
    }
  })

  config_decoder(env, data)
}

fn check_unknown_keys(
  map: Map(String, _),
  keys: List(List(String)),
) -> Result(Map(String, _), Report(Error)) {
  let unknown = {
    let keys =
      list.map(keys, set.from_list)
      |> list.fold(from: set.new(), with: set.union)

    set.from_list(map.keys(map))
    |> set.filter(fn(key) { !set.contains(keys, key) })
    |> set.to_list()
  }

  case unknown {
    [] -> Ok(map)

    keys ->
      UnknownKeys(keys)
      |> report.error()
  }
}

fn get_env(path: List(String)) -> Result(String, Nil) {
  list.reverse(path)
  |> string.join("_")
  |> os.get_env()
}

fn section(map: Map(String, Dynamic), name: String) -> Dynamic {
  map.get(map, name)
  |> result.unwrap(dynamic.from(map.new()))
}

const config_keys = ["server", "static", "gzip"]

pub type Config {
  Config(server: Server, static: Static, gzip: Gzip)
}

fn config_decoder(
  env: List(String),
  data: Dynamic,
) -> Result(Config, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.replace_error(DecodeError)
    |> result.then(check_unknown_keys(_, [config_keys])),
  )

  use server <- result.then({
    server_decoder(["SERVER", ..env], section(map, "server"))
    |> report.error_context(BadSection("server"))
  })

  use static <- result.then({
    static_decoder(["STATIC", ..env], section(map, "static"))
    |> report.error_context(BadSection("static"))
  })

  use gzip <- result.then({
    gzip_decoder(["GZIP", ..env], section(map, "gzip"))
    |> report.error_context(BadSection("gzip"))
  })

  Ok(Config(server: server, static: static, gzip: gzip))
}

const server_keys = ["port"]

pub type Server {
  Server(port: Int)
}

fn server_decoder(
  env: List(String),
  data: Dynamic,
) -> Result(Server, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadConfig("server", _))
    |> result.then(check_unknown_keys(_, [server_keys])),
  )

  use port <- result.then({
    case get_env(["PORT", ..env]) {
      Ok(value) ->
        int.parse(value)
        |> report.replace_error(BadConfig("port", []))

      Error(Nil) ->
        case map.get(map, "port") {
          Error(Nil) ->
            MissingConfig("port")
            |> report.error()

          Ok(value) ->
            dynamic.int(value)
            |> report.map_error(BadConfig("port", _))
        }
    }
  })

  Ok(Server(port: port))
}

const static_keys = ["base", "index", "types", "reloader"]

pub type Static {
  Static(
    base: String,
    index: List(String),
    types: Map(String, String),
    reloader: Option(Reloader),
  )
}

fn static_decoder(
  env: List(String),
  data: Dynamic,
) -> Result(Static, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadConfig("static", _))
    |> result.then(check_unknown_keys(_, [static_keys])),
  )

  use base <- result.then({
    case get_env(["BASE", ..env]) {
      Ok(value) -> Ok(value)

      Error(Nil) ->
        case map.get(map, "base") {
          Error(Nil) ->
            MissingConfig("base")
            |> report.error()

          Ok(value) ->
            dynamic.string(value)
            |> report.map_error(BadConfig("base", _))
        }
    }
  })

  use index <- result.then({
    case get_env(["INDEX", ..env]) {
      Ok(value) -> Ok(uri.path_segments(value))

      Error(Nil) ->
        case map.get(map, "index") {
          Error(Nil) -> Ok(["index.html"])

          Ok(value) -> {
            use index <- result.then(
              dynamic.string(value)
              |> report.map_error(BadConfig("index", _)),
            )

            Ok(uri.path_segments(index))
          }
        }
    }
  })

  use types <- result.then({
    case get_env(["TYPES", ..env]) {
      Ok(value) -> {
        use args <- result.then(
          string.split(value, ",")
          |> list.try_map(fn(arg) {
            case string.split(arg, ":") {
              [ext, kind] -> Ok(#(ext, kind))

              _ ->
                BadConfig("types", [])
                |> report.error()
            }
          }),
        )

        Ok(map.from_list(args))
      }

      Error(Nil) ->
        case map.get(map, "types") {
          Error(Nil) -> Ok(map.new())

          Ok(value) ->
            value
            |> dynamic.map(dynamic.string, dynamic.string)
            |> report.map_error(BadConfig("types", _))
        }
    }
  })

  use reloader <- result.then({
    reloader_decoder(["RELOADER", ..env], section(map, "reloader"))
    |> report.error_context(BadSection("reloader"))
  })

  Ok(Static(base: base, index: index, types: types, reloader: reloader))
}

const reloader_keys = ["method", "path"]

pub type Reloader {
  Reloader(method: http.Method, path: List(String))
}

fn reloader_decoder(
  env: List(String),
  data: Dynamic,
) -> Result(Option(Reloader), Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadConfig("reloader", _))
    |> result.then(check_unknown_keys(_, [reloader_keys])),
  )

  use method <- result.then({
    case get_env(["METHOD", ..env]) {
      Ok(value) -> {
        use method <- result.then(
          http.parse_method(value)
          |> report.replace_error(BadConfig("method", [])),
        )

        Ok(option.Some(method))
      }

      Error(Nil) ->
        case map.get(map, "method") {
          Error(Nil) -> Ok(option.None)

          Ok(value) -> {
            use string <- result.then(
              dynamic.string(value)
              |> report.map_error(BadConfig("method", _)),
            )

            use method <- result.then(
              http.parse_method(string)
              |> report.replace_error(BadConfig("method", [])),
            )

            Ok(option.Some(method))
          }
        }
    }
  })

  use path <- result.then({
    case get_env(["PATH", ..env]) {
      Ok(value) ->
        uri.path_segments(value)
        |> option.Some
        |> Ok

      Error(Nil) ->
        case map.get(map, "path") {
          Error(Nil) -> Ok(option.None)

          Ok(value) -> {
            use value <- result.then(
              dynamic.string(value)
              |> report.map_error(BadConfig("path", _)),
            )

            uri.path_segments(value)
            |> option.Some
            |> Ok
          }
        }
    }
  })

  case method, path {
    option.None, option.None -> Ok(option.None)

    option.Some(method), option.Some(path) ->
      Reloader(method: method, path: path)
      |> option.Some()
      |> Ok

    option.None, option.Some(_) ->
      MissingConfig("method")
      |> report.error()

    option.Some(_), option.None ->
      MissingConfig("path")
      |> report.error()
  }
}

const gzip_keys = ["threshold", "types"]

pub type Gzip {
  Gzip(threshold: Int, types: Set(String))
}

fn gzip_decoder(env: List(String), data: Dynamic) -> Result(Gzip, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadConfig("gzip", _))
    |> result.then(check_unknown_keys(_, [gzip_keys])),
  )

  use threshold <- result.then({
    case get_env(["THRESHOLD", ..env]) {
      Ok(value) ->
        int.parse(value)
        |> report.replace_error(BadConfig("threshold", []))

      Error(Nil) ->
        case map.get(map, "port") {
          Error(Nil) -> Ok(350)

          Ok(value) ->
            dynamic.int(value)
            |> report.map_error(BadConfig("threshold", _))
        }
    }
  })

  use types <- result.then({
    case get_env(["TYPES", ..env]) {
      Ok(value) ->
        string.split(value, ",")
        |> set.from_list()
        |> Ok

      Error(Nil) ->
        case map.get(map, "types") {
          Error(Nil) -> Ok(set.new())

          Ok(value) -> {
            use types <- result.then(
              value
              |> dynamic.list(dynamic.string)
              |> report.map_error(BadConfig("types", _)),
            )

            Ok(set.from_list(types))
          }
        }
    }
  })

  Ok(Gzip(threshold: threshold, types: types))
}

fn field(key: String, value: a) -> #(String, a) {
  #(key, value)
}

pub fn encode(config: Config) -> Json {
  json.object([
    #("server", encode_server(config.server)),
    #("static", encode_static(config.static)),
    #("gzip", encode_gzip(config.gzip)),
  ])
}

pub fn encode_server(server: Server) -> Json {
  json.object([#("port", json.int(server.port))])
}

pub fn encode_static(static: Static) -> Json {
  json.object([
    #("base", json.string(static.base)),
    #("index", json.array(static.index, json.string)),
    map.to_list(static.types)
    |> list.map(pair.map_second(_, json.string))
    |> json.object()
    |> field("types", _),
    #("reloader", json.nullable(static.reloader, encode_reloader)),
  ])
}

pub fn encode_reloader(reloader: Reloader) -> Json {
  json.object([
    http.method_to_string(reloader.method)
    |> json.string()
    |> field("method", _),
    #("path", json.array(reloader.path, json.string)),
  ])
}

pub fn encode_gzip(gzip: Gzip) -> Json {
  json.object([
    #("threshold", json.int(gzip.threshold)),
    set.to_list(gzip.types)
    |> json.array(json.string)
    |> field("types", _),
  ])
}
