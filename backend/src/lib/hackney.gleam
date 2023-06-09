import gleam/bit_builder.{BitBuilder}
import gleam/dynamic.{Dynamic}
import gleam/erlang/atom
import gleam/erlang/charlist.{Charlist}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/list
import gleam/map
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri.{Uri}

const default_options = [
  ConnectTimeout(Millis(5000)),
  MaxRedirect(0),
  RecvTimeout(Millis(5000)),
]

pub type Option {
  Proxy(Uri)
  CACertFile(String)
  ConnectTimeout(Timeout)
  RecvTimeout(Timeout)
  MaxRedirect(Int)
}

type OptionGroup {
  SSLConfig
}

pub type Timeout {
  Millis(Int)
  Infinity
}

pub type Config {
  Config(
    resolved: List(Dynamic),
    pending: List(fn(Request(BitBuilder)) -> Dynamic),
  )
}

pub fn options(keys: List(Option)) -> Config {
  let groups =
    map.to_list(
      default_options
      |> list.group(option_keys)
      |> map.merge(list.group(keys, option_keys))
      |> map.values()
      |> list.flatten()
      |> list.group(fn(config) {
        case config {
          CACertFile(_) -> Some(SSLConfig)
          _ -> None
        }
      }),
    )

  use config, group <- list.fold(groups, Config(resolved: [], pending: []))

  case group {
    #(None, keys) ->
      Config(..config, resolved: list.flat_map(keys, encode_option))

    #(Some(SSLConfig), keys) -> {
      let ssl_options = {
        let atom = atom.create_from_string("ssl_options")
        let keys = list.flat_map(keys, encode_option)

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

fn option_keys(option: Option) -> Int {
  case option {
    Proxy(_) -> 1
    CACertFile(_) -> 2
    ConnectTimeout(_) -> 3
    RecvTimeout(_) -> 4
    MaxRedirect(_) -> 5
  }
}

external fn merge_ssl_options(Charlist, List(Dynamic)) -> Dynamic =
  "hackney_connection" "merge_ssl_opts"

fn encode_option(option: Option) -> List(Dynamic) {
  case option {
    Proxy(uri) -> [encode_pair("proxy", uri.to_string(uri))]

    CACertFile(path) -> [encode_pair("cacertfile", path)]

    ConnectTimeout(timeout) -> [
      encode_pair("connect_timeout", encode_timeout(timeout)),
    ]

    RecvTimeout(timeout) -> [
      encode_pair("recv_timeout", encode_timeout(timeout)),
    ]

    MaxRedirect(limit) if limit > 0 -> [
      encode_pair("max_redirect", limit),
      encode_pair("follow_redirect", True),
    ]

    MaxRedirect(limit) -> [encode_pair("max_redirect", limit)]
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
  with config: Config,
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
