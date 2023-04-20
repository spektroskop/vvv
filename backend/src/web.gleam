import gleam
import gleam/bit_builder.{BitBuilder}
import gleam/bool
import gleam/erlang/file
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/result
import gleam/set.{Set}
import gleam/string
import lib
import lib/report.{Report}
import lib/result_extra

pub type Error {
  CallError
  FileError(file.Reason)
}

pub type Result =
  gleam.Result(Response(BitBuilder), Report(Error))

pub type Service =
  fn(Request(BitString), List(String)) -> Result

pub fn require_method(
  request: Request(_),
  valid: http.Method,
  continue: fn() -> Result,
) -> Result {
  case request.method {
    method if method == valid -> continue()

    _ ->
      response.new(405)
      |> response.set_body("405 Method Not Allowed")
      |> response.map(bit_builder.from_string)
      |> Ok
  }
}

pub fn gzip(
  request: Request(_),
  above threshold: Int,
  only kinds: Set(String),
  from get_response: fn() -> Response(BitBuilder),
) -> Response(BitBuilder) {
  let Response(body: body, ..) as response = get_response()
  use <- result_extra.else(response)

  let size = bit_builder.byte_size(body)
  use <- bool.guard(when: size < threshold, return: Error(Nil))

  use accepts <- result.then(request.get_header(request, "accept-encoding"))
  use <- bool.guard(when: !string.contains(accepts, "gzip"), return: Error(Nil))

  use kind <- result.then(response.get_header(response, "content-type"))
  use <- bool.guard(when: !set.contains(kinds, kind), return: Error(Nil))

  response
  |> response.set_body(body)
  |> response.map(lib.gzip)
  |> response.prepend_header("content-encoding", "gzip")
  |> Ok
}
