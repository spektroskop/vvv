import gleam/bit_builder
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response
import gleam/json
import gleam/result
import lib/report.{Report}
import web.{Error}
import web/static

pub type Config {
  Config(assets: fn() -> Result(static.Assets, Report(Error)))
}

pub fn router(config: Config) -> web.Service {
  fn(request: Request(_), segments: List(String)) -> web.Result {
    case request.method, segments {
      http.Get, ["assets"] -> {
        use assets <- result.then(config.assets())

        let body =
          static.encode_assets(assets)
          |> json.to_string()

        response.new(200)
        |> response.set_body(body)
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
