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
import lib
import lib/report.{Report}
import web.{Error}
import web/static.{Assets}

pub type Message {
  Reload(Subject(web.Result))
  List(Subject(Result(Assets, Report(Error))))
  Route(Request(BitString), List(String), Subject(web.Result))
}

pub fn start(service: fn() -> static.Service) -> Result(Subject(Message), _) {
  use message, state <- actor.start(service())

  case message {
    Reload(reply) -> {
      let reloaded = service()

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

pub fn service(
  method method: http.Method,
  path path: List(String),
  service service: fn() -> static.Service,
  timeout timeout: Int,
) -> Result(static.Service, actor.StartError) {
  use actor <- result.then(start(service))
  use <- lib.return(Ok)

  static.Service(
    assets: fn() {
      process.try_call(actor, List, timeout)
      |> result.unwrap(report.error(web.CallError))
    },
    router: fn(request: Request(_), segments) -> web.Result {
      case request.method == method && segments == path {
        True ->
          process.try_call(actor, Reload, timeout)
          |> result.unwrap(report.error(web.CallError))

        False ->
          process.try_call(actor, Route(request, segments, _), timeout)
          |> result.unwrap(report.error(web.CallError))
      }
    },
  )
}
