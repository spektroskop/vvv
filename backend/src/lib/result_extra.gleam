import gleam/result

pub fn unwrap_error(result: Result(a, e), or default: fn(e) -> a) -> a {
  case result {
    Ok(ok) -> ok
    Error(error) -> default(error)
  }
}

pub fn else(value: a, wrap: fn() -> Result(a, e)) -> a {
  result.unwrap(wrap(), value)
}

pub fn else_error(value: fn(e) -> a, wrap: fn() -> Result(a, e)) -> a {
  unwrap_error(wrap(), value)
}
