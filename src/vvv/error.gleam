import gleam/erlang/file

pub type Error {
  FileError(file.Reason)
  CallError
}
