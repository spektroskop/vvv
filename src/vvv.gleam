import config
import gleam/erlang/process
import gleam/http/elli
import gleam/option
import web/api
import web/reloader
import web/router
import web/static

pub fn main() {
  let assert Ok(config) = config.read(from: "vvv.toml", env_prefix: ["VVV"])

  let assert Ok(static_service) = {
    let service = fn() {
      static.service(from: config.static.base, fallback: config.static.index)
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
      gzip_threshold: 350,
      gzip_types: [
        "text/html", "text/css", "text/javascript", "application/json",
      ],
    )

  let assert Ok(_) = elli.start(router.service(routes), config.server.port)

  process.sleep_forever()
}
