import gleam/bit_builder.{BitBuilder}
import gleam/dynamic.{Dynamic}
import gleam/erlang/atom
import gleam/erlang/charlist.{Charlist}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/iterator
import gleam/list
import gleam/map
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri.{Uri}

pub type Option {
  Proxy(Uri)
  CACertFile(String)
  ConnectTimeout(Timeout)
  RecvTimeout(Timeout)
  MaxRedirect(Int)
  WithBody(Bool)
}

type OptionGroup {
  SSLConfig
}

pub type Timeout {
  Millis(Int)
  Infinity
}

pub type Config(a) {
  Config(resolved: List(Dynamic), pending: List(fn(Request(a)) -> Dynamic))
}

pub fn options(keys: List(Option)) -> Config(a) {
  let groups =
    iterator.from_list(keys)
    |> iterator.group(by: fn(config) {
      case config {
        CACertFile(_) -> Some(SSLConfig)
        _ -> None
      }
    })

  use config, group <- list.fold(
    map.to_list(groups),
    Config(resolved: [], pending: []),
  )

  case group {
    #(None, keys) -> Config(..config, resolved: list.map(keys, encode_option))

    #(Some(SSLConfig), keys) -> {
      let ssl_options = {
        let atom = atom.create_from_string("ssl_options")
        let keys = list.map(keys, encode_option)

        fn(request: Request(_)) {
          dynamic.from(#(
            atom,
            charlist.from_string(request.host)
            |> merge_ssl_options(keys),
          ))
        }
      }

      Config(..config, pending: [ssl_options, ..config.pending])
    }
  }
}

external fn merge_ssl_options(Charlist, List(Dynamic)) -> Dynamic =
  "hackney_connection" "merge_ssl_opts"

fn encode_option(option: Option) -> Dynamic {
  case option {
    Proxy(uri) -> encode_pair("proxy", uri.to_string(uri))
    CACertFile(path) -> encode_pair("cacertfile", path)
    ConnectTimeout(timeout) ->
      encode_pair("connect_timeout", encode_timeout(timeout))
    RecvTimeout(timeout) -> encode_pair("recv_timeout", encode_timeout(timeout))
    MaxRedirect(limit) -> encode_pair("max_redirect", limit)
    WithBody(bool) -> encode_pair("with_body", bool)
  }
}

fn encode_pair(key: String, value: a) -> Dynamic {
  let atom = atom.create_from_string(key)
  dynamic.from(#(atom, value))
}

fn encode_timeout(timeout: Timeout) -> Dynamic {
  case timeout {
    Millis(v) -> dynamic.from(v)
    Infinity -> dynamic.from(Infinity)
  }
}

pub type Error {
  BadResponse
  BadOption(Dynamic)
  Timeout
  Other(Dynamic)
}

pub type Body {
  Empty
  Body(BitString)
  Reference(Reference)
}

pub external type Reference

external fn hackney_send(
  http.Method,
  String,
  List(http.Header),
  BitBuilder,
  Dynamic,
) -> Result(Response(Body), Error) =
  "glue" "hackney_send"

pub fn send(
  request: Request(BitBuilder),
  with config: Config(BitBuilder),
) -> Result(Response(Body), Error) {
  let uri = uri.to_string(request.to_uri(request))
  let options =
    dynamic.from({
      use opts, f <- list.fold(config.pending, config.resolved)
      [f(request), ..opts]
    })

  use response <- result.map({
    hackney_send(request.method, uri, request.headers, request.body, options)
  })

  Response(..response, headers: list.map(response.headers, normalise_header))
}

fn normalise_header(header: #(String, _)) {
  #(string.lowercase(header.0), header.1)
}

external fn hackney_body(Reference) -> Result(BitString, Error) =
  "glue" "hackney_body"

pub fn read_body(response: Response(Body)) -> Result(Response(BitString), Error) {
  case response.body {
    Empty -> Error(BadResponse)
    Body(body) -> Ok(response.set_body(response, body))
    Reference(ref) -> {
      use body <- result.map(hackney_body(ref))
      response.set_body(response, body)
    }
  }
}
