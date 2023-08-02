import config
import gleam/erlang
import gleam/erlang/process
import gleam/http/request.{Request}
import gleam/http/response.{Response}
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

  let router =
    router.service(
      api: api.service(
        interval: config.app.interval,
        assets: static_service.assets,
        reload_browser: config.app.reload_browser,
      ),
      static: static_service,
      gzip_types: config.gzip.types,
      gzip_threshold: config.gzip.threshold,
    )

  let assert Ok(_) =
    mist.new({
      fn(request: Request(mist.Connection)) -> Response(mist.ResponseData) {
        let assert Ok(request) = mist.read_body(request, 0)
        router(request)
        |> response.map(mist.Bytes)
      }
    })
    |> mist.port(config.server.port)
    |> mist.start_http()

  process.sleep_forever()
}
