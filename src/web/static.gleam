import gleam/base
import gleam/bit_builder.{BitBuilder}
import gleam/crypto
import gleam/erlang/file
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response
import gleam/list
import gleam/map.{Map}
import gleam/result
import gleam/uri
import lib
import lib/path
import lib/report.{Report}
import vvv/error.{Error}
import web

pub type Service {
  Service(assets: fn() -> Result(Assets, Report(Error)), router: web.Service)
}

pub type Asset {
  Asset(content_type: String, hash: String, body: Body)
}

pub type Body {
  Path(String)
  Data(BitBuilder)
}

pub type Assets =
  Map(List(String), Asset)

pub fn service(from base: String, fallback index: List(String)) -> Service {
  let assets = collect(base)
  Service(assets: fn() { Ok(assets) }, router: router(assets, index))
}

fn router(assets: Assets, index: List(String)) {
  fn(request: Request(_), segments: List(String)) -> web.Result {
    use <- web.require_method(request, http.Get)

    use asset <- get_asset(request, segments, assets, index)
    use body <- result.then(case asset.body {
      Data(body) -> Ok(body)

      Path(path) ->
        file.read_bits(path)
        |> result.map(bit_builder.from_bit_string)
        |> report.map_error(error.FileError)
    })

    response.new(200)
    |> response.set_body(body)
    |> response.prepend_header("content-type", asset.content_type)
    |> response.prepend_header("etag", asset.hash)
    |> Ok
  }
}

fn get_asset(
  request: Request(_),
  segments: List(String),
  assets: Assets,
  index: List(String),
  continue: fn(Asset) -> web.Result,
) -> web.Result {
  let asset =
    map.get(assets, segments)
    |> result.or(map.get(assets, index))

  case asset {
    Error(Nil) ->
      response.new(404)
      |> response.set_body("404 Not Found")
      |> response.map(bit_builder.from_string)
      |> Ok

    Ok(asset) -> {
      let Asset(hash: hash, ..) = asset

      case request.get_header(request, "if-none-match") {
        Ok(header) if hash == header ->
          response.new(304)
          |> response.prepend_header("etag", hash)
          |> response.map(bit_builder.from_string)
          |> Ok

        _ -> continue(asset)
      }
    }
  }
}

pub fn collect(base: String) -> Assets {
  map.from_list({
    use relative_path <- list.filter_map(path.wildcard(base, "**"))
    let path = path.join([base, relative_path])
    use <- lib.guard(when: path.is_directory(path), return: Error(Nil))

    use asset <- result.then(load(path))
    let segments = uri.path_segments(relative_path)
    Ok(#(segments, asset))
  })
}

fn load(path: String) -> Result(Asset, Nil) {
  use content_type <- result.then(get_content_type(path))
  use data <- result.then(
    file.read_bits(path)
    |> result.nil_error(),
  )

  Asset(
    content_type: content_type,
    hash: crypto.hash(crypto.Sha224, data)
    |> base.encode64(False),
    // body: Data(
    //   bit_builder.from_bit_string(data)
    //   |> lib.gzip(),
    // ),
    body: Path(path),
  )
  |> Ok
}

fn get_content_type(path: String) -> Result(String, Nil) {
  case path.extension(path) {
    ".css" -> Ok("text/css")
    ".html" -> Ok("text/html")
    ".ico" -> Ok("image/x-icon")
    ".js" -> Ok("text/javascript")
    ".woff" -> Ok("font/woff")
    ".woff2" -> Ok("font/woff2")
    ".png" -> Ok("image/png")
    _unknown -> Error(Nil)
  }
}
