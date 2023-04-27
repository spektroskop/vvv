import gleam/dynamic
import gleeunit/should
import lib/dynamic as dynamic_extra

pub fn non_empty_string_test() {
  dynamic.from("")
  |> dynamic_extra.non_empty_string()
  |> should.equal(Error([
    dynamic.DecodeError(
      expected: "non-empty string",
      found: "empty string",
      path: [],
    ),
  ]))

  dynamic.from(10)
  |> dynamic_extra.non_empty_string()
  |> should.equal(Error([
    dynamic.DecodeError(expected: "String", found: "Int", path: []),
  ]))

  dynamic.from("string")
  |> dynamic_extra.non_empty_string()
  |> should.equal(Ok("string"))
}

pub fn into_list_test() {
  dynamic.from(10)
  |> dynamic_extra.into_list(dynamic.int)
  |> should.equal(Ok([10]))
}

pub fn optional_list_test() {
  dynamic.from(10)
  |> dynamic_extra.optional_list(dynamic.int)
  |> should.equal(Ok([10]))

  dynamic.from([10])
  |> dynamic_extra.optional_list(dynamic.int)
  |> should.equal(Ok([10]))
}
