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

const default_static_index = ["index.html"]

const default_static_types = [
  #("css", "text/css"),
  #("html", "text/html"),
  #("ico", "image/x-icon"),
  #("js", "text/javascript"),
  #("woff", "font/woff"),
  #("woff2", "font/woff2"),
  #("png", "image/png"),
  #("svg", "image/svg+xml"),
]

const default_gzip_threshold = 350

const default_gzip_types = [
  "text/html", "text/css", "text/javascript", "application/json",
  "image/svg+xml",
]

pub type Error {
  BadCategory(name: String)
  BadConfig(name: String, errors: dynamic.DecodeErrors)
  BadEnvironment(name: String)
  BadFormat(errors: dynamic.DecodeErrors)
  BadToml(error: Dynamic)
  FileError(reason: file.Reason)
  MissingConfig(name: String)
  UnknownKeys(keys: List(String))
}

pub fn read(prefix: List(String)) -> Result(Config, Report(Error)) {
  use data <- result.then({
    case get_env(["CONFIG", ..prefix]) {
      Error(Nil) -> Ok(dynamic.from(map.new()))

      Ok(path) -> {
        use data <- result.then(
          file.read(path)
          |> report.map_error(FileError),
        )

        decode.toml(data)
        |> report.map_error(BadToml)
      }
    }
  })

  config_decoder(prefix, data)
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

fn get_section(map: Map(String, Dynamic), name: String) -> Dynamic {
  map.get(map, name)
  |> result.unwrap(dynamic.from(map.new()))
}

const config_keys = ["server", "static", "gzip"]

pub type Config {
  Config(server: Server, static: Static, gzip: Gzip)
}

fn config_decoder(
  prefix: List(String),
  data: Dynamic,
) -> Result(Config, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadFormat)
    |> result.then(check_unknown_keys(_, [config_keys])),
  )

  use server <- result.then({
    server_decoder(["SERVER", ..prefix], get_section(map, "server"))
    |> report.error_context(BadCategory("server"))
  })

  use static <- result.then({
    static_decoder(["STATIC", ..prefix], get_section(map, "static"))
    |> report.error_context(BadCategory("static"))
  })

  use gzip <- result.then({
    gzip_decoder(["GZIP", ..prefix], get_section(map, "gzip"))
    |> report.error_context(BadCategory("gzip"))
  })

  Ok(Config(server: server, static: static, gzip: gzip))
}

const server_keys = ["port"]

pub type Server {
  Server(port: Int)
}

fn server_decoder(
  prefix: List(String),
  data: Dynamic,
) -> Result(Server, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadConfig("server", _))
    |> result.then(check_unknown_keys(_, [server_keys])),
  )

  use port <- result.then({
    case get_env(["PORT", ..prefix]), map.get(map, "port") {
      Ok(value), _map ->
        int.parse(value)
        |> report.replace_error(BadEnvironment("port"))

      _env, Ok(value) ->
        dynamic.int(value)
        |> report.map_error(BadConfig("port", _))

      _env, _map ->
        MissingConfig("port")
        |> report.error()
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
  prefix: List(String),
  data: Dynamic,
) -> Result(Static, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadConfig("static", _))
    |> result.then(check_unknown_keys(_, [static_keys])),
  )

  use base <- result.then({
    case get_env(["BASE", ..prefix]), map.get(map, "base") {
      Ok(value), _map -> Ok(value)

      _env, Ok(value) ->
        dynamic.string(value)
        |> report.map_error(BadConfig("base", _))

      _env, _map ->
        MissingConfig("base")
        |> report.error()
    }
  })

  use index <- result.then({
    case get_env(["INDEX", ..prefix]), map.get(map, "index") {
      Ok(value), _map -> Ok(uri.path_segments(value))

      _env, Ok(value) -> {
        use index <- result.then(
          dynamic.string(value)
          |> report.map_error(BadConfig("index", _)),
        )

        Ok(uri.path_segments(index))
      }

      _env, _map -> Ok(default_static_index)
    }
  })

  use types <- result.then({
    case get_env(["TYPES", ..prefix]), map.get(map, "types") {
      Ok(value), _map -> {
        use args <- result.then({
          use arg <- list.try_map(string.split(value, ","))

          case string.split(arg, ":") {
            [ext, kind] -> Ok(#(ext, kind))

            _ ->
              BadEnvironment("types")
              |> report.error()
          }
        })

        Ok(map.from_list(args))
      }

      _env, Ok(value) ->
        value
        |> dynamic.map(dynamic.string, dynamic.string)
        |> report.map_error(BadConfig("types", _))

      _env, _map -> Ok(map.from_list(default_static_types))
    }
  })

  use reloader <- result.then({
    reloader_decoder(["RELOADER", ..prefix], get_section(map, "reloader"))
    |> report.error_context(BadCategory("reloader"))
  })

  Ok(Static(base: base, index: index, types: types, reloader: reloader))
}

const reloader_keys = ["method", "path"]

pub type Reloader {
  Reloader(method: http.Method, path: List(String))
}

fn reloader_decoder(
  prefix: List(String),
  data: Dynamic,
) -> Result(Option(Reloader), Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadConfig("reloader", _))
    |> result.then(check_unknown_keys(_, [reloader_keys])),
  )

  use method <- result.then({
    case get_env(["METHOD", ..prefix]), map.get(map, "method") {
      Ok(value), _map -> {
        use method <- result.then(
          http.parse_method(value)
          |> report.replace_error(BadEnvironment("method")),
        )

        Ok(option.Some(method))
      }

      _env, Ok(value) -> {
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

      _env, _map -> Ok(option.None)
    }
  })

  use path <- result.then({
    case get_env(["PATH", ..prefix]), map.get(map, "path") {
      Ok(value), _map ->
        uri.path_segments(value)
        |> option.Some
        |> Ok

      _env, Ok(value) -> {
        use value <- result.then(
          dynamic.string(value)
          |> report.map_error(BadConfig("path", _)),
        )

        uri.path_segments(value)
        |> option.Some
        |> Ok
      }

      _env, _map -> Ok(option.None)
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

fn gzip_decoder(
  prefix: List(String),
  data: Dynamic,
) -> Result(Gzip, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.map_error(BadConfig("gzip", _))
    |> result.then(check_unknown_keys(_, [gzip_keys])),
  )

  use threshold <- result.then({
    case get_env(["THRESHOLD", ..prefix]), map.get(map, "threshold") {
      Ok(value), _map ->
        int.parse(value)
        |> report.replace_error(BadEnvironment("threshold"))

      _env, Ok(value) ->
        dynamic.int(value)
        |> report.map_error(BadConfig("threshold", _))

      _env, _map -> Ok(default_gzip_threshold)
    }
  })

  use types <- result.then({
    case get_env(["TYPES", ..prefix]), map.get(map, "types") {
      Ok(value), _map ->
        string.split(value, ",")
        |> set.from_list()
        |> Ok

      _env, Ok(value) -> {
        use types <- result.then(
          value
          |> dynamic.list(dynamic.string)
          |> report.map_error(BadConfig("types", _)),
        )

        Ok(set.from_list(types))
      }

      _env, _map -> Ok(set.from_list(default_gzip_types))
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

fn encode_server(server: Server) -> Json {
  json.object([#("port", json.int(server.port))])
}

fn encode_static(static: Static) -> Json {
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

fn encode_reloader(reloader: Reloader) -> Json {
  json.object([
    http.method_to_string(reloader.method)
    |> json.string()
    |> field("method", _),
    #("path", json.array(reloader.path, json.string)),
  ])
}

fn encode_gzip(gzip: Gzip) -> Json {
  json.object([
    #("threshold", json.int(gzip.threshold)),
    set.to_list(gzip.types)
    |> json.array(json.string)
    |> field("types", _),
  ])
}
