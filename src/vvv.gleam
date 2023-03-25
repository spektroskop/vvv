import config
import gleam/erlang
import gleam/erlang/process
import gleam/http/elli
import gleam/option
import gleam/string
import web/api
import web/reloader
import web/router
import web/static

pub fn main() {
  let #(config_file, env_prefix) = case erlang.start_arguments() {
    [] -> #(option.None, [])
    [env_prefix] -> #(option.None, string.split(env_prefix, "_"))
    [env_prefix, path] -> #(option.Some(path), string.split(env_prefix, "_"))
  }

  let assert Ok(config) =
    config.read(from: config_file, env_prefix: env_prefix)

  let assert Ok(static_service) = {
    let service = fn() {
      static.service(
        from: config.static.base,
        fallback: config.static.index,
        types: config.static.types,
      )
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

  process.sleep_forever()
}
