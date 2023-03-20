import gleam/erlang/process.{Subject}
import gleam/http
import gleam/http/request.{Request}
import gleam/json
import gleam/list
import gleam/otp/actor
import gleam/pair
import gleam/result
import lib/report.{Report}
import vvv/error.{Error}
import web
import web/static.{Assets}

const call_timeout = 1000

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
              static.diff(old, new)
              |> list.map(pair.map_second(_, json.array(_, json.string)))
              |> json.object()
              |> web.json(200, _)
            }

            _, _ -> web.string(500, "500 Internal Server Error")
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

fn assets(actor) -> fn() -> Result(Assets, _) {
  fn() {
    process.try_call(actor, List, call_timeout)
    |> result.unwrap(report.error(error.CallError))
  }
}

fn router(actor: Actor, method: http.Method, path: List(String)) -> web.Service {
  fn(request: Request(_), segments) -> web.Result {
    case request.method == method && segments == path {
      True ->
        process.try_call(actor, Reload, call_timeout)
        |> result.unwrap(report.error(error.CallError))

      False ->
        process.try_call(actor, Route(request, segments, _), call_timeout)
        |> result.unwrap(report.error(error.CallError))
    }
  }
}

pub fn service(
  config: Config,
  reload: fn() -> static.Service,
) -> Result(static.Service, actor.StartError) {
  use actor <- result.then(start(reload))

  static.Service(
    assets: assets(actor),
    router: router(actor, config.method, config.path),
  )
  |> Ok
}
