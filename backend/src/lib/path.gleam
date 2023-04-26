import gleam/erlang/charlist.{Charlist}
import gleam/list

pub external fn join_absolute(name: String, other: String) -> String =
  "filename" "absname_join"

pub external fn basename(name: String) -> String =
  "filename" "basename"

pub external fn is_directory(path: String) -> Bool =
  "filelib" "is_dir"

pub external fn join(List(String)) -> String =
  "filename" "join"

pub external fn extension(String) -> String =
  "filename" "extension"

pub fn wildcard(in dir: String, find pattern: String) -> List(String) {
  charlist.from_string(pattern)
  |> filelib_wildcard(charlist.from_string(dir))
  |> list.map(charlist.to_string)
}

external fn filelib_wildcard(Charlist, Charlist) -> List(Charlist) =
  "filelib" "wildcard"
