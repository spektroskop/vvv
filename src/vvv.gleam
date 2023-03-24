import gleam/erlang/os
import gleam/erlang/process
import gleam/http
import gleam/http/elli
import gleam/int
import gleam/option
import gleam/result
import gleam/uri
import lib
import web/api
import web/reloader
import web/router
import web/static

pub fn main() {
  let assert Ok(port) =
    os.get_env("PORT")
    |> result.then(int.parse)

  let assert Ok(asset_path) = os.get_env("ASSET_PATH")

  let index_path =
    os.get_env("INDEX_PATH")
    |> result.map(uri.path_segments)
    |> result.unwrap(["index.html"])

  let static_reloader = {
    use <- lib.else(option.None)

    use path <- result.then(
      os.get_env("RELOADER_PATH")
      |> result.map(uri.path_segments),
    )
    use method <- result.then(
      os.get_env("RELOADER_METHOD")
      |> result.then(http.parse_method),
    )

    reloader.Config(method, path)
    |> option.Some
    |> Ok
  }

  let assert Ok(static_service) = {
    let service = fn() {
      static.service(from: asset_path, fallback: index_path)
    }

    case static_reloader {
      option.Some(config) -> reloader.service(config, service)
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

  let assert Ok(_) = elli.start(router.service(routes), port)

  process.sleep_forever()
}
