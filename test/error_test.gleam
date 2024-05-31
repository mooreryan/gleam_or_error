import birdie
import gleam/json
import gleam/option.{None, Some}
import gleam/order
import gleeunit/should
import or_error/error
import qcheck/generator as gen
import qcheck/qtest

pub fn compare__test() {
  let e1 = error.from_string("e1")
  let e2 = error.from_string("e2")

  error.compare(e1, e2) |> should.equal(order.Lt)
  error.compare(e1, e1) |> should.equal(order.Eq)
  error.compare(e2, e2) |> should.equal(order.Eq)
  error.compare(e2, e1) |> should.equal(order.Gt)
}

pub fn equal__test() {
  let e1 = error.from_string("e1")
  let e2 = error.from_string("e2")

  error.equal(e1, e2) |> should.be_false
  error.equal(e1, e1) |> should.be_true
  error.equal(e2, e2) |> should.be_true
  error.equal(e2, e1) |> should.be_false
}

pub fn from_json__test() {
  let e = error.from_json(json.string("yo!"))

  e |> error.to_string |> should.equal("\"yo!\"")
}

pub fn to_json_internal__test() {
  let err =
    error.from_string("the error")
    |> error.tag("tag one")
    |> error.tag("tag two")
    |> error.tag("tag three")

  err
  |> error.to_json_internal
  |> json.to_string
  |> birdie.snap("error_test.to_json_internal__test")
}

pub fn to_json__test() {
  let err =
    error.from_string("the error")
    |> error.tag("tag one")
    |> error.tag("tag two")
    |> error.tag("tag three")

  err
  |> error.to_json
  |> json.to_string
  |> birdie.snap("error_test.to_json__test")
}

pub fn to_string__test() {
  let err =
    error.from_string("the error")
    |> error.tag("tag one")
    |> error.tag("tag two")
    |> error.tag("tag three")

  err
  |> error.to_string
  |> birdie.snap("error_test.to_string__test")
}

pub fn from_string_to_string_round_trip__test() {
  let s = "this: is [some}]i2 weird !@#$%$#@ thing"

  should.equal(error.to_string(error.from_string(s)), s)
}

pub fn from_string_to_string_round_trip__prop_test() {
  use s <- qtest.given(gen.string())
  error.to_string(error.from_string(s)) == s
}

pub fn from_list__no_truncate_after__test() {
  let errors = [
    error.from_string("a error") |> error.tag("a tag"),
    error.from_string("b error") |> error.tag("b tag"),
    error.from_string("c error") |> error.tag("c tag"),
  ]

  error.from_list(errors)
  |> error.to_string
  |> should.equal("a tag: a error; b tag: b error; c tag: c error")
}

pub fn from_list__truncate_after_1__test() {
  let errors = [
    error.from_string("a error") |> error.tag("a tag"),
    error.from_string("b error") |> error.tag("b tag"),
    error.from_string("c error") |> error.tag("c tag"),
  ]

  error.from_list_truncate_after(errors, 1)
  |> error.to_string
  |> should.equal("a tag: a error; and 2 more errors")
}

pub fn from_list__truncate_after_2__test() {
  let errors = [
    error.from_string("a error") |> error.tag("a tag"),
    error.from_string("b error") |> error.tag("b tag"),
    error.from_string("c error") |> error.tag("c tag"),
  ]

  error.from_list_truncate_after(errors, 2)
  |> error.to_string
  |> should.equal("a tag: a error; b tag: b error; and 1 more error")
}

pub fn from_list__truncate_after_3__test() {
  let errors = [
    error.from_string("a error") |> error.tag("a tag"),
    error.from_string("b error") |> error.tag("b tag"),
    error.from_string("c error") |> error.tag("c tag"),
  ]

  error.from_list_truncate_after(errors, 3)
  |> error.to_string
  |> should.equal("a tag: a error; b tag: b error; c tag: c error")
}
