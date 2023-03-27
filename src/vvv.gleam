import config
import gleam/erlang
import gleam/erlang/process
import gleam/http/elli
import gleam/io
import gleam/json
import gleam/option
import gleam/string
import web/api
import web/reloader
import web/router
import web/static

pub fn main() {
  let prefix = case erlang.start_arguments() {
    [] -> []
    [prefix, ..] -> string.split(prefix, "_")
  }

  let assert Ok(config) = config.read(prefix)

  json.to_string(config.encode(config))
  |> io.println()

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
        reloader.service(reloader.Config(
          method: method,
          path: path,
          service: service,
          timeout: 250,
        ))

      option.None -> Ok(service())
    }
  }

  let assert Ok(_) =
    elli.start(
      router.service(router.Config(
        api: api.service(api.Config(assets: static_service.assets)),
        static: static_service,
        gzip_threshold: config.gzip.threshold,
        gzip_types: config.gzip.types,
      )),
      config.server.port,
    )

  process.sleep_forever()
}
