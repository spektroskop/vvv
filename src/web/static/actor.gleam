import gleam/bit_builder
import gleam/erlang/process.{Subject}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/option.{Option}
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

pub type Reloader {
  Reloader(method: http.Method, path: List(String))
}

pub fn start(
  from base: String,
  fallback index: List(String),
) -> Result(Subject(Message), actor.StartError) {
  actor.start(
    static.service(base, index),
    fn(message, state) -> actor.Next(_) {
      case message {
        Reload(reply) -> {
          Ok(Response(200, [], bit_builder.from_string("ok")))
          |> process.send(reply, _)

          static.service(base, index)
          |> actor.Continue()
        }

        List(reply) -> {
          state.assets()
          |> process.send(reply, _)

          actor.Continue(state)
        }

        Route(request, segments, reply) -> {
          state.router(request, segments)
          |> process.send(reply, _)

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
  reloader: Option(Reloader),
  from base: String,
  fallback index: List(String),
) -> Result(static.Service, actor.StartError) {
  case reloader {
    option.None ->
      static.service(base, index)
      |> Ok

    option.Some(Reloader(method, path)) -> {
      use actor <- result.then(start(from: base, fallback: index))

      static.Service(assets: assets(actor), router: router(actor, method, path))
      |> Ok
    }
  }
}
