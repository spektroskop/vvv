import config
import gleam/erlang
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import mist
import web/api
import web/reloader
import web/router
import web/static

pub fn main() {
  let assert Ok(config) =
    config.read({
      case erlang.start_arguments() {
        [] -> []

        [prefix] ->
          string.split(string.trim(prefix), "_")
          |> list.filter(fn(part) { !string.is_empty(part) })

        _args -> panic
      }
    })

  io.println(
    config.encode(config)
    |> json.to_string(),
  )

  let assert Ok(static_service) = {
    let service = fn() {
      static.service(
        types: config.static.types,
        base: config.static.base,
        index: config.static.index,
      )
    }

    case config.static.reloader {
      option.None -> Ok(service())

      option.Some(config.Reloader(method, path)) ->
        reloader.service(
          method: method,
          path: path,
          timeout: 250,
          service: service,
        )
    }
  }

  let assert Ok(_) =
    mist.run_service(
      config.server.port,
      router.service(
        api: api.service(
          interval: config.app.interval,
          assets: static_service.assets,
          reload_browser: config.app.reload_browser,
        ),
        static: static_service,
        gzip_types: config.gzip.types,
        gzip_threshold: config.gzip.threshold,
      ),
      max_body_limit: 0,
    )

  process.sleep_forever()
}