import gleam
import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/list
import gleam/result
import gleam/string
import lib
import lib/report.{Report}
import vvv/error.{Error}

pub type Result =
  gleam.Result(Response(BitBuilder), Report(Error))

pub type Service =
  fn(Request(BitString), List(String)) -> Result

pub fn try_(
  result: gleam.Result(a, b),
  or alternative: fn() -> Result,
  then continue: fn(a) -> Result,
) -> Result {
  case result {
    Ok(value) -> continue(value)
    Error(_) -> alternative()
  }
}

pub fn require_method(
  request: Request(_),
  valid: http.Method,
  continue: fn() -> Result,
) -> Result {
  case request.method {
    method if method == valid -> continue()

    _ ->
      response.new(400)
      |> response.set_body("400 Bad Request")
      |> response.map(bit_builder.from_string)
      |> Ok
  }
}

pub fn gzip(
  request: Request(_),
  above limit: Int,
  only compressable: List(String),
  from get_response: fn() -> Response(BitBuilder),
) -> Response(BitBuilder) {
  let Response(body: body, ..) as response = get_response()
  use <- lib.else(response)

  use <- lib.when(bit_builder.byte_size(body) >= limit)
  use accepts <- result.then(request.get_header(request, "accept-encoding"))
  use <- lib.when(string.contains(accepts, "gzip"))
  use kind <- result.then(response.get_header(response, "content-type"))
  use <- lib.when(list.contains(compressable, kind))

  response
  |> response.map(lib.gzip)
  |> response.prepend_header("content-encoding", "gzip")
  |> Ok
}
