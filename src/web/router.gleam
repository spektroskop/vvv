import gleam/bit_builder
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import gleam/set.{Set}
import web
import web/static

pub type Config {
  Config(
    api: web.Service,
    static: static.Service,
    gzip_threshold: Int,
    gzip_types: Set(String),
  )
}

pub fn service(config: Config) -> Service(_, _) {
  fn(request: Request(_)) -> Response(_) {
    use <- web.gzip(
      request,
      only: config.gzip_types,
      above: config.gzip_threshold,
    )

    case request.path_segments(request) {
      ["api", ..segments] ->
        case config.api(request, segments) {
          Ok(response) ->
            response
            |> response.prepend_header("cache-control", "no-cache")

          Error(_report) ->
            response.new(500)
            |> response.set_body("500 Internal Server Error")
            |> response.map(bit_builder.from_string)
        }

      segments ->
        case config.static.router(request, segments) {
          Ok(response) ->
            response
            |> response.prepend_header("cache-control", "no-cache")

          Error(_report) ->
            response.new(500)
            |> response.set_body("500 Internal Server Error")
            |> response.map(bit_builder.from_string)
        }
    }
  }
}
