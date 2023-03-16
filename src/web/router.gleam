import gleam/bit_builder
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import web
import web/static

pub type Config {
  Config(static: static.Service, gzip_above: Int, gzip_types: List(String))
}

pub fn service(config: Config) -> Service(_, _) {
  let Config(static: static, ..) = config

  fn(request: Request(_)) -> Response(_) {
    use <- web.gzip(request, only: config.gzip_types, above: config.gzip_above)

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
