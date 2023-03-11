import gleam/erlang/os
import gleam/erlang/process
import gleam/http
import gleam/option
import gleam/result
import gleam/uri
import lib
import mist
import web/router
import web/static/actor as static

pub fn main() {
  let assert Ok(static_path) = os.get_env("STATIC_PATH")

  let index_path =
    os.get_env("INDEX_PATH")
    |> result.map(uri.path_segments)
    |> result.unwrap(["index.html"])

  let reloader = {
    use <- lib.wrap(result.unwrap(_, option.None))

    use path <- result.then(
      os.get_env("RELOADER_PATH")
      |> result.map(fn(path) { [path] }),
    )
    use method <- result.then(
      os.get_env("RELOADER_METHOD")
      |> result.then(http.parse_method),
    )

    static.Reloader(method, path)
    |> option.Some()
    |> Ok()
  }

  let assert Ok(static_service) =
    static.service(reloader, from: static_path, fallback: index_path)

  let routes = router.Config(static: static_service)
  let router = router.service(routes)

  let assert Ok(_) = mist.run_service(3210, router, max_body_limit: 0)

  process.sleep_forever()
}
