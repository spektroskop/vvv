import gleam/dynamic
import gleeunit/should
import lib/dynamic_extra

pub fn decode_non_empty_string_test() {
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

pub fn decode_optional_list_test() {
  dynamic.from(10)
  |> dynamic_extra.optional_list(dynamic_extra.non_empty_string)
  |> should.equal(Error([dynamic.DecodeError("another type", "Int", [])]))

  dynamic.from([10])
  |> dynamic_extra.optional_list(dynamic_extra.non_empty_string)
  |> should.equal(Error([dynamic.DecodeError("another type", "List", [])]))

  dynamic.from("value")
  |> dynamic_extra.optional_list(dynamic_extra.non_empty_string)
  |> should.equal(Ok(["value"]))

  dynamic.from(["value"])
  |> dynamic_extra.optional_list(dynamic_extra.non_empty_string)
  |> should.equal(Ok(["value"]))
}
