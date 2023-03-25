import gleam/erlang/charlist.{Charlist}
import gleam/list

pub external fn basename(name: String) -> String =
  "filename" "basename"

pub external fn is_directory(path: String) -> Bool =
  "filelib" "is_dir"

pub external fn join(List(String)) -> String =
  "filename" "join"

pub external fn extension(String) -> String =
  "filename" "extension"

pub fn wildcard(from cwd: String, find pattern: String) -> List(String) {
  charlist.from_string(pattern)
  |> filepath_wildcard(charlist.from_string(cwd))
  |> list.map(charlist.to_string)
}

external fn filepath_wildcard(Charlist, Charlist) -> List(Charlist) =
  "filelib" "wildcard"
