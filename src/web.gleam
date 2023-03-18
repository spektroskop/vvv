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
  gleam.Result(Response(Body), Report(Error))

pub type Body {
  StringBody(String)
  GzipBody(BitBuilder)
  BytesBody(BitBuilder)
  EmptyBody
}

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
      response.new(400)
      |> response.set_body("400 Bad Request")
      |> response.map(StringBody)
      |> Ok
  }
}

pub fn gzip(
  request: Request(_),
  above limit: Int,
  only compressable: List(String),
  from get_response: fn() -> Response(Body),
) -> Response(BitBuilder) {
  let Response(body: body, ..) as response = get_response()

  let compress = fn(data) {
    use <- lib.else(response.set_body(response, data))

    use <- lib.when(bit_builder.byte_size(data) >= limit)
    use accepts <- result.then(request.get_header(request, "accept-encoding"))
    use <- lib.when(string.contains(accepts, "gzip"))
    use kind <- result.then(response.get_header(response, "content-type"))
    use <- lib.when(list.contains(compressable, kind))

    response
    |> response.set_body(data)
    |> response.map(lib.gzip)
    |> response.prepend_header("content-encoding", "gzip")
    |> Ok
  }

  case body {
    BytesBody(body) -> compress(body)
    StringBody(body) ->
      bit_builder.from_string(body)
      |> compress()
    EmptyBody ->
      bit_builder.new()
      |> response.set_body(response, _)
    GzipBody(bytes) ->
      response.set_body(response, bytes)
      |> response.prepend_header("content-encoding", "gzip")
  }
}

pub fn response(get_response: fn() -> Response(Body)) -> Response(BitBuilder) {
  let Response(body: body, ..) as response = get_response()

  case body {
    BytesBody(body) -> response.set_body(response, body)
    StringBody(body) ->
      bit_builder.from_string(body)
      |> response.set_body(response, _)
    EmptyBody ->
      bit_builder.new()
      |> response.set_body(response, _)
    GzipBody(bytes) ->
      response.set_body(response, bytes)
      |> response.prepend_header("content-encoding", "gzip")
  }
}
