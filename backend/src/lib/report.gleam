pub type Report(issue) {
  Report(issue: issue, context: List(issue))
}

pub fn new(issue: issue) -> Report(issue) {
  Report(issue: issue, context: [])
}

pub fn error(issue: issue) -> Result(success, Report(issue)) {
  Error(new(issue))
}

pub fn context(report: Report(issue), issue: issue) -> Report(issue) {
  Report(issue: issue, context: [report.issue, ..report.context])
}

pub fn map_error(
  result: Result(value, error),
  mapper: fn(error) -> issue,
) -> Result(value, Report(issue)) {
  case result {
    Ok(value) -> Ok(value)

    Error(err) ->
      mapper(err)
      |> error()
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

pub fn error_context(
  result: Result(value, Report(issue)),
  issue: issue,
) -> Result(value, Report(issue)) {
  case result {
    Ok(value) -> Ok(value)

    Error(report) ->
      context(report, issue)
      |> Error
  }
}

pub fn with_error_context(
  issue: issue,
  result: fn() -> Result(value, Report(issue)),
) -> Result(value, Report(issue)) {
  case result() {
    Ok(value) -> Ok(value)

    Error(report) ->
      context(report, issue)
      |> Error
  }
}
