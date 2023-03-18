import gleam/erlang/process.{Subject}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response
import gleam/otp/actor
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

pub fn start(reload: fn() -> static.Service) -> Result(Subject(Message), _) {
  actor.start(
    reload(),
    fn(message, state) -> actor.Next(_) {
      case message {
        Reload(reply) -> {
          process.send(
            reply,
            response.new(200)
            |> response.set_body(web.StringBody("ok"))
            |> Ok,
          )

          actor.Continue(reload())
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
    },
  )
}

fn assets(actor) -> fn() -> Result(Assets, _) {
  fn() {
    process.try_call(actor, List, call_timeout)
    |> result.unwrap(report.error(error.CallError))
  }
}

fn router(actor, method, path) -> web.Service {
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
