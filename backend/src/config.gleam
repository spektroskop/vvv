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
import lib/dynamic as dynamic_extra
import lib/report.{Report}
import lib/toml

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
  BadConfig(name: String)
  BadEnvironment(name: String)
  BadToml(error: Dynamic)
  DecodeError(errors: dynamic.DecodeErrors)
  FileError(reason: file.Reason)
  MissingConfig(name: String)
  UnknownKeys(keys: List(String))
}

pub fn error_context(result: Result(_, dynamic.DecodeErrors), context: Error) {
  report.map_error(result, DecodeError)
  |> report.error_context(context)
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

        toml.decode(data)
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

const config_keys = ["app", "server", "static", "gzip"]

pub type Config {
  Config(app: App, server: Server, static: Static, gzip: Gzip)
}

fn category_decoder(
  name: String,
  from data: Dynamic,
  with keys: List(String),
) -> Result(Map(String, Dynamic), Report(Error)) {
  data
  |> dynamic_extra.shallow_map(dynamic_extra.non_empty_string)
  |> error_context(BadCategory(name))
  |> result.then(check_unknown_keys(_, [keys]))
}

fn config_decoder(
  prefix: List(String),
  data: Dynamic,
) -> Result(Config, Report(Error)) {
  use map <- result.then({
    category_decoder("config", from: data, with: config_keys)
  })

  use app <- result.then({
    app_decoder(["APP", ..prefix], get_section(map, "app"))
    |> report.error_context(BadCategory("app"))
  })

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

  Config(app: app, server: server, static: static, gzip: gzip)
  |> Ok
}

const app_keys = ["interval", "reload_browser"]

pub type App {
  App(interval: Int, reload_browser: Bool)
}

fn app_decoder(
  prefix: List(String),
  data: Dynamic,
) -> Result(App, Report(Error)) {
  use map <- result.then({ category_decoder("app", from: data, with: app_keys) })

  use interval <- result.then({
    case get_env(["INTERVAL", ..prefix]), map.get(map, "interval") {
      Ok(value), _map ->
        int.parse(value)
        |> report.replace_error(BadEnvironment("interval"))

      _env, Ok(value) ->
        dynamic.int(value)
        |> error_context(BadConfig("interval"))

      _env, _map -> Ok(5000)
    }
  })

  use reload_browser <- result.then({
    case get_env(["RELOAD_BROWSER", ..prefix]), map.get(map, "reload_browser") {
      Ok(value), _map ->
        json.decode(value, dynamic.bool)
        |> report.replace_error(BadEnvironment("reload_browser"))

      Ok(_), _map ->
        BadEnvironment("reload_browser")
        |> report.error()

      _env, Ok(value) ->
        dynamic.bool(value)
        |> error_context(BadConfig("reload_browser"))

      _env, _map -> Ok(False)
    }
  })

  App(interval: interval, reload_browser: reload_browser)
  |> Ok
}

const server_keys = ["port"]

pub type Server {
  Server(port: Int)
}

fn server_decoder(
  prefix: List(String),
  data: Dynamic,
) -> Result(Server, Report(Error)) {
  use map <- result.then({
    category_decoder("server", from: data, with: server_keys)
  })

  use port <- result.then({
    case get_env(["PORT", ..prefix]), map.get(map, "port") {
      Ok(value), _map ->
        int.parse(value)
        |> report.replace_error(BadEnvironment("port"))

      _env, Ok(value) ->
        dynamic.int(value)
        |> error_context(BadConfig("port"))

      _env, _map ->
        MissingConfig("port")
        |> report.error()
    }
  })

  Server(port: port)
  |> Ok
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
  use map <- result.then({
    category_decoder("static", from: data, with: static_keys)
  })

  use base <- result.then({
    case get_env(["BASE", ..prefix]), map.get(map, "base") {
      Ok(value), _map -> Ok(value)

      _env, Ok(value) ->
        dynamic.string(value)
        |> error_context(BadConfig("base"))

      _env, _map ->
        MissingConfig("base")
        |> report.error()
    }
  })

  use index <- result.then({
    case get_env(["INDEX", ..prefix]), map.get(map, "index") {
      Ok(value), _map -> Ok(uri.path_segments(value))

      _env, Ok(value) -> {
        use string <- result.then(
          dynamic.string(value)
          |> error_context(BadConfig("index")),
        )

        uri.path_segments(string)
        |> Ok
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

        map.from_list(args)
        |> Ok
      }

      _env, Ok(value) ->
        value
        |> dynamic.map(dynamic.string, dynamic.string)
        |> error_context(BadConfig("types"))

      _env, _map ->
        map.from_list(default_static_types)
        |> Ok
    }
  })

  use reloader <- result.then({
    reloader_decoder(["RELOADER", ..prefix], get_section(map, "reloader"))
    |> report.error_context(BadCategory("reloader"))
  })

  Static(base: base, index: index, types: types, reloader: reloader)
  |> Ok
}

const reloader_keys = ["method", "path"]

pub type Reloader {
  Reloader(method: http.Method, path: List(String))
}

fn reloader_decoder(
  prefix: List(String),
  data: Dynamic,
) -> Result(Option(Reloader), Report(Error)) {
  use map <- result.then({
    category_decoder("reloader", from: data, with: reloader_keys)
  })

  use method <- result.then({
    case get_env(["METHOD", ..prefix]), map.get(map, "method") {
      Ok(value), _map -> {
        use method <- result.then(
          http.parse_method(value)
          |> report.replace_error(BadEnvironment("method")),
        )

        option.Some(method)
        |> Ok
      }

      _env, Ok(value) -> {
        use string <- result.then(
          dynamic.string(value)
          |> error_context(BadConfig("method")),
        )

        use method <- result.then(
          http.parse_method(string)
          |> report.replace_error(BadConfig("method")),
        )

        option.Some(method)
        |> Ok
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
        use string <- result.then(
          dynamic.string(value)
          |> error_context(BadConfig("path")),
        )

        uri.path_segments(string)
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
  use map <- result.then({
    category_decoder("gzip", from: data, with: gzip_keys)
  })

  use threshold <- result.then({
    case get_env(["THRESHOLD", ..prefix]), map.get(map, "threshold") {
      Ok(value), _map ->
        int.parse(value)
        |> report.replace_error(BadEnvironment("threshold"))

      _env, Ok(value) ->
        dynamic.int(value)
        |> error_context(BadConfig("threshold"))

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
        use list <- result.then(
          value
          |> dynamic.list(dynamic.string)
          |> error_context(BadConfig("types")),
        )

        set.from_list(list)
        |> Ok
      }

      _env, _map ->
        set.from_list(default_gzip_types)
        |> Ok
    }
  })

  Gzip(threshold: threshold, types: types)
  |> Ok
}

pub fn encode(config: Config) -> Json {
  json.object([
    #("app", encode_app(config.app)),
    #("server", encode_server(config.server)),
    #("static", encode_static(config.static)),
    #("gzip", encode_gzip(config.gzip)),
  ])
}

fn encode_app(app: App) -> Json {
  json.object([
    #("interval", json.int(app.interval)),
    #("reload_browser", json.bool(app.reload_browser)),
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
