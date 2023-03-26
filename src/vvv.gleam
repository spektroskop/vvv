import config
import gleam/erlang
import gleam/erlang/process
import gleam/http/elli
import gleam/json
import gleam/option
import gleam/string
import lib/log
import web/api
import web/reloader
import web/router
import web/static

pub fn main() {
  let env = case erlang.start_arguments() {
    [] -> []
    [env, ..] -> string.split(env, "_")
  }

  let assert Ok(config) = config.read(env)

  log.message(
    "starting",
    [
      log.string("config", string.inspect(config_file)),
      log.string("prefix", string.inspect(env_prefix)),
    ],
  )

  log.message(
    "static",
    [
      config.encode_static(config.static)
      |> json.to_string()
      |> log.string("config", _),
    ],
  )

  log.message(
    "gzip",
    [
      config.encode_gzip(config.gzip)
      |> json.to_string()
      |> log.string("config", _),
    ],
  )

  let assert Ok(static_service) = {
    let service = fn() {
      static.service(static.Config(
        types: config.static.types,
        base: config.static.base,
        index: config.static.index,
      ))
    }

    case config.static.reloader {
      option.Some(config.Reloader(method, path)) ->
        reloader.service(method, path, service)

      option.None -> Ok(service())
    }
  }

  let routes =
    router.Config(
      api: api.router(api.Config(assets: static_service.assets)),
      static: static_service,
      gzip_threshold: config.gzip.threshold,
      gzip_types: config.gzip.types,
    )

  let assert Ok(_) = elli.start(router.service(routes), config.server.port)

  log.message("server listening", [log.int("port", config.server.port)])
  process.sleep_forever()
}
