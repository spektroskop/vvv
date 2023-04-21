pub fn unwrap_error(result: Result(a, e), or default: fn(e) -> a) -> a {
  case result {
    Ok(ok) -> ok
    Error(error) -> default(error)
  }
}
