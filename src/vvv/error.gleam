import gleam/erlang/file

pub type Error {
  CallError
  FileError(file.Reason)
}
