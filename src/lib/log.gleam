import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam_community/ansi
import gleam_community/colour
import lib/time.{DateTime}

pub type Field {
  Field(name: String, value: String)
}

pub fn string(name: String, value: String) -> Field {
  Field(name: name, value: value)
}

pub fn int(name: String, value: Int) -> Field {
  Field(name: name, value: int.to_string(value))
}

pub fn bool(name: String, value: Bool) -> Field {
  Field(
    name: name,
    value: bool.to_string(value)
    |> string.lowercase(),
  )
}

pub fn message(message: String, fields: List(Field)) {
  let colour =
    colour.from_rgb_hex(0x6097a8)
    |> result.unwrap(colour.red)

  println(message, ansi.colour(_, colour), fields)
}

pub fn println(
  message: String,
  style: fn(String) -> String,
  fields: List(Field),
) -> Nil {
  let DateTime(date, time) = time.now()

  let year = int.to_string(date.year)
  let month = pad_zero(date.month)
  let day = pad_zero(date.day)
  let hour = pad_zero(time.hour)
  let minute = pad_zero(time.minute)
  let second = pad_zero(time.second)
  let show_time = string.concat([hour, ":", minute, ":", second])
  let _show_date = string.concat([year, "-", month, "-", day])

  let main = [
    // ansi.bright_black(show_date),
    ansi.bright_black(show_time),
    style(message),
  ]

  let fields =
    list.map(fields, format_field)
    |> list.sort(by: string.compare)

  list.flatten([main, fields])
  |> string.join(" ")
  |> io.println()
}

fn format_field(field: Field) -> String {
  string.concat([
    ansi.bright_black(field.name),
    ansi.bright_black("=")
    |> ansi.bold(),
    field.value,
  ])
}

fn pad_zero(v) {
  let n = int.to_string(v)

  case string.length(n) {
    1 -> string.concat(["0", n])
    _else -> n
  }
}
