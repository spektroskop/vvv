import gleam/bit_builder
import gleam/erlang/process.{Subject}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response
import gleam/json
import gleam/list
import gleam/otp/actor
import gleam/pair
import gleam/result
import lib/report.{Report}
import web.{Error}
import web/static.{Assets}

pub type Actor =
  Subject(Message)

pub type Message {
  Reload(Subject(web.Result))
  List(Subject(Result(Assets, Report(Error))))
  Route(Request(BitString), List(String), Subject(web.Result))
}

pub type Config {
  Config(method: http.Method, path: List(String))
}

pub fn start(service: fn() -> static.Service) -> Result(Subject(Message), _) {
  actor.start(service(), update(service))
}

fn update(reload: fn() -> static.Service) {
  fn(message, state: static.Service) -> actor.Next(static.Service) {
    case message {
      Reload(reply) -> {
        let reloaded = reload()

        process.send(
          reply,
          case state.assets(), reloaded.assets() {
            Ok(old), Ok(new) -> {
              let changes =
                static.changes(from: old, to: new)
                |> list.map(pair.map_second(_, json.array(_, json.string)))
                |> json.object()
                |> json.to_string()

              response.new(200)
              |> response.prepend_header("content-type", "application/json")
              |> response.set_body(changes)
              |> response.map(bit_builder.from_string)
              |> Ok
            }

            _, _ ->
              response.new(500)
              |> response.set_body("500 Internal Server Error")
              |> response.map(bit_builder.from_string)
              |> Ok
          },
        )

        actor.Continue(reloaded)
      }

      List(reply) -> {
        process.send(reply, state.assets())
        actor.Continue(state)
      }

      Route(request, segments, reply) -> {
        process.send(reply, state.router(request, segments))
        actor.Continue(state)
      }
    }
  }
}

fn assets(actor: Actor, timeout timeout: Int) -> fn() -> Result(Assets, _) {
  fn() {
    process.try_call(actor, List, timeout)
    |> result.unwrap(report.error(web.CallError))
  }
}

fn router(
  actor: Actor,
  method: http.Method,
  path: List(String),
  timeout timeout: Int,
) -> web.Service {
  fn(request: Request(_), segments) -> web.Result {
    case request.method == method && segments == path {
      True ->
        process.try_call(actor, Reload, timeout)
        |> result.unwrap(report.error(web.CallError))

      False ->
        process.try_call(actor, Route(request, segments, _), timeout)
        |> result.unwrap(report.error(web.CallError))
    }
  }
}

pub fn service(
  config: Config,
  reload: fn() -> static.Service,
) -> Result(static.Service, actor.StartError) {
  use actor <- result.then(start(reload))

  static.Service(
    assets: assets(actor, timeout: 250),
    router: router(actor, config.method, config.path, timeout: 250),
  )
  |> Ok
}
