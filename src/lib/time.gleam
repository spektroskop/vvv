pub type Date {
  Date(year: Int, month: Int, day: Int)
}

pub type Time {
  Time(hour: Int, minute: Int, second: Int)
}

pub type DateTime {
  DateTime(Date, Time)
}

external fn glue_now() -> #(#(Int, Int, Int), #(Int, Int, Int)) =
  "glue" "now"

pub fn now() -> DateTime {
  let #(#(year, month, day), #(hour, minute, second)) = glue_now()
  let date = Date(year, month, day)
  let time = Time(hour, minute, second)
  DateTime(date, time)
}
