import gleam/string

pub fn to_result(string: String) -> Result(String, Nil) {
  case string {
    "" -> Error(Nil)
    _string -> Ok(string)
  }
}

pub fn to_non_empty(string: String) -> Result(String, Nil) {
  string.trim(string)
  |> to_result()
}
