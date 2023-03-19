import gleam/bit_builder
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response
import web

pub fn router(request: Request(_), segments: List(String)) -> web.Result {
  case request.method, segments {
    http.Get, ["something"] ->
      response.new(200)
      |> response.set_body("Hei")
      |> response.map(bit_builder.from_string)
      |> Ok

    _, _ ->
      response.new(404)
      |> response.set_body("404 Not Found")
      |> response.map(bit_builder.from_string)
      |> Ok
  }
}
