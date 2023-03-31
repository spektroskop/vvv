import gleam/bit_builder
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response
import gleam/json
import gleam/result
import lib/report.{Report}
import web.{Error}
import web/static

pub fn service(
  assets get_assets: fn() -> Result(static.Assets, Report(Error)),
  reload_browser reload_browser: Bool,
  interval interval: Int,
) -> web.Service {
  fn(request: Request(_), segments: List(String)) -> web.Result {
    case request.method, segments {
      http.Get, ["app"] -> {
        use assets <- result.then(get_assets())

        let body =
          json.object([
            #("interval", json.int(interval)),
            #("assets", static.encode_assets(assets)),
            #("reload_browser", json.bool(reload_browser)),
          ])
          |> json.to_string()

        response.new(200)
        |> response.set_body(body)
        |> response.prepend_header("content-type", "application/json")
        |> response.map(bit_builder.from_string)
        |> Ok
      }

      http.Get, ["assets"] -> {
        use assets <- result.then(get_assets())

        let body =
          static.encode_assets(assets)
          |> json.to_string()

        response.new(200)
        |> response.set_body(body)
        |> response.prepend_header("content-type", "application/json")
        |> response.map(bit_builder.from_string)
        |> Ok
      }

      _, _ ->
        response.new(404)
        |> response.set_body("404 Not Found")
        |> response.map(bit_builder.from_string)
        |> Ok
    }
  }
}
