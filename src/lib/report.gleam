pub type Report(issue) {
  Report(issue: issue, context: List(issue))
}

pub fn new(issue: issue) -> Report(issue) {
  Report(issue: issue, context: [])
}

pub fn error(issue: issue) -> Result(success, Report(issue)) {
  Error(new(issue))
}

pub fn map_error(
  result: Result(value, error),
  f: fn(error) -> issue,
) -> Result(value, Report(issue)) {
  case result {
    Ok(value) -> Ok(value)
    Error(err) -> error(f(err))
  }
}

pub fn replace_error(
  result: Result(value, _),
  issue: issue,
) -> Result(value, Report(issue)) {
  case result {
    Ok(value) -> Ok(value)
    Error(_) -> error(issue)
  }
}
