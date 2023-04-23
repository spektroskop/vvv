import gleam/result

pub fn unwrap_error(result: Result(a, e), or else: fn(e) -> a) -> a {
  result
  |> result.map_error(else)
  |> result.unwrap_both()
}
