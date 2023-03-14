import gleam/bit_builder
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import web
import web/static

pub type Config {
  Config(static: static.Service)
}

const compressable = [
  "text/html", "text/css", "text/javascript", "application/json",
]

pub fn service(routes: Config) -> Service(_, _) {
  let Config(static: static) = routes

  fn(request: Request(_)) -> Response(_) {
    use <- web.gzip(request, only: compressable, above: 1000)

    case request.path_segments(request) {
      segments ->
        case static.router(request, segments) {
          Ok(response) -> response

          Error(_report) ->
            response.new(500)
            |> response.set_body("500 Internal Server Error")
            |> response.map(bit_builder.from_string)
        }
    }
  }
}
