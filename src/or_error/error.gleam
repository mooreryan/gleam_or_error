import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string

/// 
pub opaque type Error {
  String(String)
  Tagged(String, Error)
  FromList(Option(Int), List(Error))
  Json(Json)
}

/// 
pub fn compare(t1: Error, t2: Error) -> order.Order {
  let s1 = json.to_string(to_json_internal(t1))
  let s2 = json.to_string(to_json_internal(t2))

  string.compare(s1, s2)
}

///
pub fn equal(t1: Error, t2: Error) -> Bool {
  let s1 = json.to_string(to_json_internal(t1))
  let s2 = json.to_string(to_json_internal(t2))

  s1 == s2
}

///
pub fn from_json(json) -> Error {
  Json(json)
}

pub fn to_json_internal(error: Error) -> Json {
  case error {
    String(str) -> json.array(["String", str], of: json.string)
    Tagged(str, error) -> {
      let str = json.string(str)
      let error = to_json_internal(error)
      json.preprocessed_array([json.string("Tagged"), str, error])
    }
    FromList(i, errors) -> {
      let i = json.nullable(i, of: json.int)
      let errors = json.array(errors, of: to_json_internal)
      json.preprocessed_array([json.string("FromList"), i, errors])
    }
    Json(json) -> json.preprocessed_array([json.string("Json"), json])
  }
}

fn to_jsons(error: Error, acc: List(Json)) -> List(Json) {
  case error {
    String(s) -> [json.string(s), ..acc]
    Tagged(tag, error) -> {
      let hd = json.string(tag)
      let tl = to_jsons(error, [])
      [json.preprocessed_array([hd, ..tl]), ..acc]
    }
    FromList(_, errors) ->
      list.fold(list.reverse(errors), acc, fn(acc, error) {
        to_jsons(error, acc)
      })
    Json(json) -> [json, ..acc]
  }
}

pub fn to_json(error: Error) -> Json {
  case to_jsons(error, []) {
    [json] -> json
    jsons -> json.preprocessed_array(jsons)
  }
}

pub fn from_string(s: String) -> Error {
  String(s)
}

pub fn from_any(any: any) -> Error {
  from_string(string.inspect(any))
}

fn extra_errors_msg(n n, max max) {
  case n - max {
    1 -> "and 1 more error"
    n -> "and " <> int.to_string(n) <> " more errors"
  }
}

fn to_strings(error: Error, acc: List(String)) -> List(String) {
  case error {
    String(str) -> [str, ..acc]
    Tagged(tag, error) -> [tag, ": ", ..to_strings(error, acc)]
    FromList(truncate_after, errors) -> {
      let errors = case truncate_after {
        None -> errors
        Some(max) -> {
          let n = list.length(errors)
          case n <= max {
            True -> errors
            False -> {
              list.append(list.take(errors, max), [
                String(extra_errors_msg(n: n, max: max)),
              ])
            }
          }
        }
      }
      list.fold(list.reverse(errors), acc, fn(acc, error) {
        to_strings(error, case acc {
          [] -> acc
          acc -> ["; ", ..acc]
        })
      })
    }
    Json(json) -> [json.to_string(json), ..acc]
  }
}

// TODO: to_string_mach
///
pub fn to_string(error: Error) -> String {
  to_strings(error, [])
  |> string.join("")
}

///
pub fn from_list(ts: List(Error)) -> Error {
  FromList(None, ts)
}

///
pub fn from_list_truncate_after(ts: List(Error), truncate_after: Int) -> Error {
  FromList(Some(truncate_after), ts)
}

///
pub fn tag(error: Error, tag tag: String) -> Error {
  Tagged(tag, error)
}
