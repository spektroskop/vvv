import gleam/dynamic
import gleeunit/should
import lib/decode

pub fn decode_non_empty_string_test() {
  dynamic.from("")
  |> decode.non_empty_string()
  |> should.equal(Error([
    dynamic.DecodeError(
      expected: "non-empty string",
      found: "empty string",
      path: [],
    ),
  ]))

  dynamic.from(10)
  |> decode.non_empty_string()
  |> should.equal(Error([
    dynamic.DecodeError(expected: "String", found: "Int", path: []),
  ]))

  dynamic.from("string")
  |> decode.non_empty_string()
  |> should.equal(Ok("string"))
}

pub fn decode_optional_list_test() {
  dynamic.from(10)
  |> decode.optional_list(decode.non_empty_string)
  |> should.equal(Error([dynamic.DecodeError("another type", "Int", [])]))

  dynamic.from([10])
  |> decode.optional_list(decode.non_empty_string)
  |> should.equal(Error([dynamic.DecodeError("another type", "List", [])]))

  dynamic.from("value")
  |> decode.optional_list(decode.non_empty_string)
  |> should.equal(Ok(["value"]))

  dynamic.from(["value"])
  |> decode.optional_list(decode.non_empty_string)
  |> should.equal(Ok(["value"]))
}
