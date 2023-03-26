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
  FileError(file.Reason)
  DecodeError
  UnknownKeys(List(String))
  BadSection(String)
  MissingConfig(String)
  BadConfig(String)
}

const config_keys = ["server", "static", "gzip"]

pub type Config {
  Config(server: Server, static: Static, gzip: Gzip)
}

const server_keys = ["port"]

pub type Server {
  Server(port: Int)
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

const reloader_keys = ["method", "path"]

pub type Reloader {
  Reloader(method: http.Method, path: List(String))
}

const gzip_keys = ["threshold", "types"]

pub type Gzip {
  Gzip(threshold: Int, types: Set(String))
}

pub fn read(
  env_prefix env: List(String),
  from path: Option(String),
) -> Result(Config, Report(Error)) {
  use data <- result.then(case path {
    option.None -> Ok(dynamic.from(map.new()))

    option.Some(path) -> {
      use data <- result.then(
        file.read(path)
        |> report.map_error(FileError),
      )

      decode.toml(data)
      |> report.replace_error(DecodeError)
    }
  })

  config_decoder(env, data)
}

fn check_unknown_keys(
  map: Map(String, _),
  keys: List(List(String)),
) -> Result(Map(String, _), Report(Error)) {
  let set =
    list.map(keys, set.from_list)
    |> list.fold(from: set.new(), with: set.union)

  let unknown_keys =
    set.from_list(map.keys(map))
    |> set.filter(fn(key) { !set.contains(set, key) })
    |> set.to_list()

  case unknown_keys {
    [] -> Ok(map)
    keys -> report.error(UnknownKeys(keys))
  }
}

fn get_env(path: List(String)) -> Result(String, Nil) {
  list.reverse(path)
  |> string.join("_")
  |> os.get_env()
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
    use <- report.use_error_context(BadSection("server"))
    let map = result.unwrap(map.get(map, "server"), dynamic.from(map.new()))
    server_decoder(["SERVER", ..env], map)
  })

  use static <- result.then({
    use <- report.use_error_context(BadSection("static"))
    let map = result.unwrap(map.get(map, "static"), dynamic.from(map.new()))
    static_decoder(["STATIC", ..env], map)
  })

  use gzip <- result.then({
    use <- report.use_error_context(BadSection("gzip"))
    let map = result.unwrap(map.get(map, "gzip"), dynamic.from(map.new()))
    gzip_decoder(["GZIP", ..env], map)
  })

  Ok(Config(server: server, static: static, gzip: gzip))
}

fn server_decoder(
  env: List(String),
  data: Dynamic,
) -> Result(Server, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.replace_error(BadConfig("server"))
    |> result.then(check_unknown_keys(_, [server_keys])),
  )

  use port <- result.then({
    case get_env(["PORT", ..env]) {
      Ok(value) ->
        int.parse(value)
        |> report.replace_error(BadConfig("port"))

      Error(Nil) ->
        case map.get(map, "port") {
          Ok(value) ->
            dynamic.int(value)
            |> report.replace_error(BadConfig("port"))

          Error(Nil) -> report.error(MissingConfig("port"))
        }
    }
  })

  Ok(Server(port: port))
}

fn static_decoder(
  env: List(String),
  data: Dynamic,
) -> Result(Static, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.replace_error(BadConfig("static"))
    |> result.then(check_unknown_keys(_, [static_keys])),
  )

  use base <- result.then({
    case get_env(["BASE", ..env]) {
      Ok(value) -> Ok(value)

      Error(Nil) ->
        case map.get(map, "base") {
          Ok(value) ->
            dynamic.string(value)
            |> report.replace_error(BadConfig("base"))

          Error(Nil) -> report.error(MissingConfig("base"))
        }
    }
  })

  use index <- result.then({
    case get_env(["INDEX", ..env]) {
      Ok(value) -> Ok(uri.path_segments(value))

      Error(Nil) ->
        case map.get(map, "index") {
          Ok(value) ->
            dynamic.string(value)
            |> report.replace_error(BadConfig("index"))
            |> result.map(uri.path_segments)

          Error(Nil) -> Ok(["index.html"])
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
              _else -> report.error(BadConfig("types"))
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
            |> report.replace_error(BadConfig("types"))

          Error(Nil) -> Ok(map.new())
        }
    }
  })

  use reloader <- result.then({
    use <- report.use_error_context(BadSection("reloader"))
    let map = result.unwrap(map.get(map, "reloader"), dynamic.from(map.new()))
    reloader_decoder(["RELOADER", ..env], map)
  })

  Ok(Static(base: base, index: index, types: types, reloader: reloader))
}

fn reloader_decoder(
  env: List(String),
  data: Dynamic,
) -> Result(Option(Reloader), Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.replace_error(BadConfig("reloader"))
    |> result.then(check_unknown_keys(_, [reloader_keys])),
  )

  use method <- result.then({
    case get_env(["METHOD", ..env]) {
      Ok(value) ->
        http.parse_method(value)
        |> report.replace_error(BadConfig("method"))
        |> result.map(option.Some)

      Error(Nil) ->
        case map.get(map, "method") {
          Ok(value) -> {
            use method <- result.then(
              dynamic.string(value)
              |> report.replace_error(BadConfig("method")),
            )

            http.parse_method(method)
            |> report.replace_error(BadConfig("method"))
            |> result.map(option.Some)
          }

          Error(Nil) -> Ok(option.None)
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
          Ok(value) ->
            dynamic.string(value)
            |> report.replace_error(BadConfig("path"))
            |> result.map(uri.path_segments)
            |> result.map(option.Some)

          Error(Nil) -> Ok(option.None)
        }
    }
  })

  case method, path {
    option.None, option.None -> Ok(option.None)
    option.Some(method), option.Some(path) ->
      Ok(option.Some(Reloader(method: method, path: path)))

    option.None, option.Some(_) -> report.error(MissingConfig("method"))
    option.Some(_), option.None -> report.error(MissingConfig("path"))
  }
}

fn gzip_decoder(env: List(String), data: Dynamic) -> Result(Gzip, Report(Error)) {
  use map <- result.then(
    data
    |> decode.shallow_map(dynamic.string)
    |> report.replace_error(BadConfig("gzip"))
    |> result.then(check_unknown_keys(_, [gzip_keys])),
  )

  use threshold <- result.then({
    case get_env(["THRESHOLD", ..env]) {
      Ok(value) ->
        int.parse(value)
        |> report.replace_error(BadConfig("threshold"))

      Error(Nil) ->
        case map.get(map, "port") {
          Ok(value) ->
            dynamic.int(value)
            |> report.replace_error(BadConfig("threshold"))

          Error(Nil) -> Ok(1000)
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
          Ok(value) ->
            value
            |> dynamic.list(dynamic.string)
            |> report.replace_error(BadConfig("types"))
            |> result.map(set.from_list)

          Error(Nil) -> Ok(set.new())
        }
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
