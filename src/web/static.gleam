import gleam/base
import gleam/bit_builder
import gleam/crypto
import gleam/erlang/file
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response
import gleam/list
import gleam/map.{Map}
import gleam/result
import gleam/set
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
  Asset(content_type: String, hash: String, path: String)
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

    use asset <- get_asset(
      for: request,
      from: map.get(assets, segments)
      |> result.or(map.get(assets, index)),
    )

    use body <- result.then(
      file.read_bits(asset.path)
      |> result.map(bit_builder.from_bit_string)
      |> report.map_error(error.FileError),
    )

    response.new(200)
    |> response.set_body(body)
    |> response.prepend_header("content-type", asset.content_type)
    |> response.prepend_header("etag", asset.hash)
    |> Ok
  }
}

fn get_asset(
  from asset: Result(Asset, Nil),
  for request: Request(_),
  then continue: fn(Asset) -> web.Result,
) -> web.Result {
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
    let full_path = path.join([base, relative_path])
    use <- lib.guard(when: path.is_directory(full_path), return: Error(Nil))

    use asset <- result.then(load(full_path))
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
    path: path,
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

pub fn changes(from old: Assets, to new: Assets) {
  let new_keys =
    map.keys(new)
    |> set.from_list()

  let old_keys =
    map.keys(old)
    |> set.from_list()

  let removed =
    set.filter(old_keys, fn(key) { !set.contains(new_keys, key) })
    |> set.to_list()

  let added =
    set.filter(new_keys, fn(key) { !set.contains(old_keys, key) })
    |> set.to_list()

  let #(changed, _) =
    set.intersection(old_keys, new_keys)
    |> set.to_list()
    |> list.partition(fn(key) { map.get(old, key) != map.get(new, key) })

  [
    #("removed", list.map(removed, path.join)),
    #("added", list.map(added, path.join)),
    #("changed", list.map(changed, path.join)),
  ]
}
