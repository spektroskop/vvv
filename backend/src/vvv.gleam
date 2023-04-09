import config
import gleam/erlang
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import mist
import mist/handler
import mist/http as mh
import mist/websocket as ws
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
    mist.serve(
      port: config.server.port,
      handler: {
        use request <- handler.with_func()

        let connect = fn(client) {
          io.debug(#("connect", client))
          ws.send(client, ws.TextMessage("Connected"))
          Nil
        }

        let close = fn(client) {
          io.debug(#("close", client))
          Nil
        }

        let handler = ws.WebsocketHandler(
          on_init: option.Some(connect),
          on_close: option.Some(close),
          handler: _,
        )

        case request.method, request.path_segments(request) {
          http.Get, ["ws"] -> {
            handler.Upgrade({
              use message, _client <- handler()
              io.debug(message)
              Ok(Nil)
            })
          }

          _method, _segments -> {
            let assert Ok(request) = mh.read_body(request)

            router(request)
            |> response.map(mh.BitBuilderBody)
            |> handler.Response
          }
        }
      },
    )

  process.sleep_forever()
}
