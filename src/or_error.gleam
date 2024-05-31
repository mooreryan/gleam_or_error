import gleam/bool
import gleam/function
import gleam/json.{type Json}
import gleam/order
import gleam/result
import or_error/error.{type Error}

// Note: on all the funN functions, we go up to N=9 because that is what the
// gleam/dynamic module does.  And those are what you often want to use with the
// applicative style error handling.

pub type OrError(a) =
  Result(a, Error)

fn result_combine_errors(
  ts: List(Result(ok, error)),
) -> Result(List(ok), List(error)) {
  let #(okays, errors) = result.partition(ts)
  case errors {
    [] -> Ok(okays)
    _ -> Error(errors)
  }
}

fn do_combine_errors(
  ts: List(OrError(a)),
  on_ok on_ok: fn(List(a)) -> b,
  on_error on_error: fn(List(Error)) -> Error,
) {
  case result_combine_errors(ts) {
    Ok(xs) -> Ok(on_ok(xs))
    Error(errors) -> Error(on_error(errors))
  }
}

fn error_from_list_if_necessary(e: List(Error)) -> Error {
  case e {
    [e] -> e
    l -> error.from_list(l)
  }
}

fn ignore_nil_list(_: List(Nil)) -> Nil {
  Nil
}

// This behavior is different from the standard Result.all as it will give all the errors.
pub fn all(ts: List(OrError(a))) -> OrError(List(a)) {
  do_combine_errors(
    ts,
    on_ok: function.identity,
    on_error: error_from_list_if_necessary,
  )
}

pub fn all_nil(ts: List(OrError(Nil))) -> OrError(Nil) {
  do_combine_errors(
    ts,
    on_ok: ignore_nil_list,
    on_error: error_from_list_if_necessary,
  )
}

pub fn combine_errors(ts: List(OrError(a))) -> OrError(List(a)) {
  do_combine_errors(ts, on_ok: function.identity, on_error: error.from_list)
}

pub fn combine_errors_nil(ts: List(OrError(Nil))) -> OrError(Nil) {
  do_combine_errors(ts, on_ok: ignore_nil_list, on_error: error.from_list)
}

fn result_compare(ok_cmp, err_cmp, r1, r2) {
  use <- bool.guard(when: r1 == r2, return: order.Eq)

  case r1, r2 {
    Ok(a), Ok(b) -> ok_cmp(a, b)
    Ok(_), Error(_) -> order.Lt
    Error(_), Ok(_) -> order.Gt
    Error(a), Error(b) -> err_cmp(a, b)
  }
}

pub fn compare(
  cmp: fn(a, a) -> order.Order,
  t1: OrError(a),
  t2: OrError(a),
) -> order.Order {
  result_compare(cmp, error.compare, t1, t2)
}

fn result_equal(ok_eq, err_eq, r1, r2) {
  use <- bool.guard(when: r1 == r2, return: True)

  case r1, r2 {
    Ok(a), Ok(b) -> ok_eq(a, b)
    Ok(_), Error(_) | Error(_), Ok(_) -> False
    Error(a), Error(b) -> err_eq(a, b)
  }
}

pub fn equal(eq: fn(a, a) -> Bool, t1: OrError(a), t2: OrError(a)) -> Bool {
  result_equal(eq, error.equal, t1, t2)
}

pub fn tag(ta: OrError(a), tag tag: String) -> OrError(a) {
  result.map_error(ta, error.tag(_, tag))
}

pub fn error_string(msg: String) -> OrError(a) {
  Error(error.from_string(msg))
}

pub fn error_json(json: Json) -> OrError(a) {
  Error(error.from_json(json))
}

pub fn to_string(ta: OrError(a), a_to_string: fn(a) -> String) -> String {
  case ta {
    Ok(a) -> "Ok: " <> a_to_string(a)
    Error(error) -> "Error: " <> error.to_string(error)
  }
}

pub fn to_json(ta: OrError(a), a_to_json: fn(a) -> Json) -> Json {
  case ta {
    Ok(a) -> json.preprocessed_array([json.string("Ok"), a_to_json(a)])
    Error(error) ->
      json.preprocessed_array([json.string("Error"), error.to_json(error)])
  }
}

pub fn from_result_map_error(
  result: Result(a, error),
  map_error: fn(error) -> Error,
) -> OrError(a) {
  result.map_error(result, map_error)
}

pub fn from_result(result: Result(a, error)) -> OrError(a) {
  result.map_error(result, error.from_any)
}

pub fn ignore_m(t: OrError(a)) -> OrError(Nil) {
  map(t, fn(_) { Nil })
}

pub fn is_error(t: OrError(a)) -> Bool {
  case t {
    Ok(_) -> False
    Error(_) -> True
  }
}

pub fn is_ok(t: OrError(a)) -> Bool {
  case t {
    Ok(_) -> True
    Error(_) -> False
  }
}

pub fn iter(t: OrError(a), f: fn(a) -> Nil) -> Nil {
  case t {
    Ok(x) -> f(x)
    Error(_) -> Nil
  }
}

pub fn iter_error(t: OrError(a), f: fn(Error) -> Nil) -> Nil {
  case t {
    Ok(_) -> Nil
    Error(e) -> f(e)
  }
}

pub fn join(tt: OrError(OrError(a))) -> OrError(a) {
  bind(tt, function.identity)
}

pub fn flatten(tt: OrError(OrError(a))) -> OrError(a) {
  join(tt)
}

pub fn unwrap(t: OrError(a), default: a) -> a {
  case t {
    Ok(x) -> x
    Error(_) -> default
  }
}

pub fn lazy_unwrap(t: OrError(a), default: fn() -> a) -> a {
  case t {
    Ok(x) -> x
    Error(_) -> default()
  }
}

// See ignore_m
pub fn replace(t: OrError(a), a: a) -> OrError(a) {
  case t {
    Ok(_) -> Ok(a)
    Error(_) as e -> e
  }
}

pub fn values(ts: List(OrError(a))) -> List(a) {
  result.values(ts)
}

pub fn return(a: a) -> OrError(a) {
  Ok(a)
}

pub fn return_curry2(f: fn(x1, x2) -> y) -> OrError(fn(x1) -> fn(x2) -> y) {
  Ok(curry2(f))
}

pub fn return_curry3(
  f: fn(x1, x2, x3) -> y,
) -> OrError(fn(x1) -> fn(x2) -> fn(x3) -> y) {
  Ok(curry3(f))
}

pub fn return_curry4(
  f: fn(x1, x2, x3, x4) -> y,
) -> OrError(fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> y) {
  Ok(curry4(f))
}

pub fn return_curry5(
  f: fn(x1, x2, x3, x4, x5) -> y,
) -> OrError(fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> y) {
  Ok(curry5(f))
}

pub fn return_curry6(
  f: fn(x1, x2, x3, x4, x5, x6) -> y,
) -> OrError(fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> fn(x6) -> y) {
  Ok(curry6(f))
}

pub fn return_curry7(
  f: fn(x1, x2, x3, x4, x5, x6, x7) -> y,
) -> OrError(
  fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> fn(x6) -> fn(x7) -> y,
) {
  Ok(curry7(f))
}

pub fn return_curry8(
  f: fn(x1, x2, x3, x4, x5, x6, x7, x8) -> y,
) -> OrError(
  fn(x1) ->
    fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> fn(x6) -> fn(x7) -> fn(x8) -> y,
) {
  Ok(curry8(f))
}

pub fn return_curry9(
  f: fn(x1, x2, x3, x4, x5, x6, x7, x8, x9) -> y,
) -> OrError(
  fn(x1) ->
    fn(x2) ->
      fn(x3) -> fn(x4) -> fn(x5) -> fn(x6) -> fn(x7) -> fn(x8) -> fn(x9) -> y,
) {
  Ok(curry9(f))
}

pub fn bind(ta: OrError(a), f: fn(a) -> OrError(b)) -> OrError(b) {
  case ta {
    Ok(x) -> f(x)
    Error(e) -> Error(e)
  }
}

pub fn then(ta: OrError(a), f: fn(a) -> OrError(b)) -> OrError(b) {
  bind(ta, f)
}

pub fn try(ta: OrError(a), f: fn(a) -> OrError(b)) -> OrError(b) {
  bind(ta, f)
}

pub fn try_recover(ta: OrError(a), f: fn(Error) -> OrError(a)) -> OrError(a) {
  result.try_recover(ta, f)
}

pub fn map(ta: OrError(a), f: fn(a) -> b) -> OrError(b) {
  case ta {
    Ok(x) -> Ok(f(x))
    Error(e) -> Error(e)
  }
}

pub fn map2(ta: OrError(a), tb: OrError(b), f: fn(a, b) -> c) -> OrError(c) {
  case ta, tb {
    Ok(x), Ok(y) -> Ok(f(x, y))
    Ok(_), Error(e) | Error(e), Ok(_) -> Error(e)
    Error(e1), Error(e2) -> Error(error.from_list([e1, e2]))
  }
}

pub fn map3(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  f: fn(t1, t2, t3) -> y,
) -> OrError(y) {
  map(t1, curry3(f)) |> apply(t2) |> apply(t3)
}

pub fn map4(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  f: fn(t1, t2, t3, t4) -> y,
) -> OrError(y) {
  map(t1, curry4(f)) |> apply(t2) |> apply(t3) |> apply(t4)
}

pub fn map5(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  f: fn(t1, t2, t3, t4, t5) -> y,
) -> OrError(y) {
  map(t1, curry5(f)) |> apply(t2) |> apply(t3) |> apply(t4) |> apply(t5)
}

pub fn map6(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  t6: OrError(t6),
  f: fn(t1, t2, t3, t4, t5, t6) -> y,
) -> OrError(y) {
  map(t1, curry6(f))
  |> apply(t2)
  |> apply(t3)
  |> apply(t4)
  |> apply(t5)
  |> apply(t6)
}

pub fn map7(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  t6: OrError(t6),
  t7: OrError(t7),
  f: fn(t1, t2, t3, t4, t5, t6, t7) -> y,
) -> OrError(y) {
  map(t1, curry7(f))
  |> apply(t2)
  |> apply(t3)
  |> apply(t4)
  |> apply(t5)
  |> apply(t6)
  |> apply(t7)
}

pub fn map8(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  t6: OrError(t6),
  t7: OrError(t7),
  t8: OrError(t8),
  f: fn(t1, t2, t3, t4, t5, t6, t7, t8) -> y,
) -> OrError(y) {
  map(t1, curry8(f))
  |> apply(t2)
  |> apply(t3)
  |> apply(t4)
  |> apply(t5)
  |> apply(t6)
  |> apply(t7)
  |> apply(t8)
}

pub fn map9(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  t6: OrError(t6),
  t7: OrError(t7),
  t8: OrError(t8),
  t9: OrError(t9),
  f: fn(t1, t2, t3, t4, t5, t6, t7, t8, t9) -> y,
) -> OrError(y) {
  map(t1, curry9(f))
  |> apply(t2)
  |> apply(t3)
  |> apply(t4)
  |> apply(t5)
  |> apply(t6)
  |> apply(t7)
  |> apply(t8)
  |> apply(t9)
}

pub fn apply(tf: OrError(fn(a) -> b), ta: OrError(a)) -> OrError(b) {
  map2(tf, ta, fn(f, a) { f(a) })
}

pub fn both(ta: OrError(a), tb: OrError(b)) -> OrError(#(a, b)) {
  map2(ta, tb, fn(a, b) { #(a, b) })
}

pub fn both_(ta: OrError(a), f: fn() -> OrError(b)) -> OrError(#(a, b)) {
  map2(ta, f(), fn(a, b) { #(a, b) })
}

pub fn tuple2(ta: OrError(a), tb: OrError(b)) -> OrError(#(a, b)) {
  both(ta, tb)
}

pub fn tuple3(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
) -> OrError(#(t1, t2, t3)) {
  let f = fn(tup) {
    let #(t1, #(t2, t3)) = tup
    #(t1, t2, t3)
  }

  both(t1, both(t2, t3))
  |> map(f)
}

pub fn tuple4(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
) -> OrError(#(t1, t2, t3, t4)) {
  let f = fn(tup) {
    let #(t1, #(t2, #(t3, t4))) = tup
    #(t1, t2, t3, t4)
  }

  both(t1, both(t2, both(t3, t4)))
  |> map(f)
}

pub fn tuple5(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
) -> OrError(#(t1, t2, t3, t4, t5)) {
  let f = fn(tup) {
    let #(t1, #(t2, #(t3, #(t4, t5)))) = tup
    #(t1, t2, t3, t4, t5)
  }

  both(t1, both(t2, both(t3, both(t4, t5))))
  |> map(f)
}

pub fn tuple6(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  t6: OrError(t6),
) -> OrError(#(t1, t2, t3, t4, t5, t6)) {
  let f = fn(tup) {
    let #(t1, #(t2, #(t3, #(t4, #(t5, t6))))) = tup
    #(t1, t2, t3, t4, t5, t6)
  }

  both(t1, both(t2, both(t3, both(t4, both(t5, t6)))))
  |> map(f)
}

pub fn tuple7(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  t6: OrError(t6),
  t7: OrError(t7),
) -> OrError(#(t1, t2, t3, t4, t5, t6, t7)) {
  let f = fn(tup) {
    let #(t1, #(t2, #(t3, #(t4, #(t5, #(t6, t7)))))) = tup
    #(t1, t2, t3, t4, t5, t6, t7)
  }

  both(t1, both(t2, both(t3, both(t4, both(t5, both(t6, t7))))))
  |> map(f)
}

pub fn tuple8(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  t6: OrError(t6),
  t7: OrError(t7),
  t8: OrError(t8),
) -> OrError(#(t1, t2, t3, t4, t5, t6, t7, t8)) {
  let f = fn(tup) {
    let #(t1, #(t2, #(t3, #(t4, #(t5, #(t6, #(t7, t8))))))) = tup
    #(t1, t2, t3, t4, t5, t6, t7, t8)
  }

  both(t1, both(t2, both(t3, both(t4, both(t5, both(t6, both(t7, t8)))))))
  |> map(f)
}

pub fn tuple9(
  t1: OrError(t1),
  t2: OrError(t2),
  t3: OrError(t3),
  t4: OrError(t4),
  t5: OrError(t5),
  t6: OrError(t6),
  t7: OrError(t7),
  t8: OrError(t8),
  t9: OrError(t9),
) -> OrError(#(t1, t2, t3, t4, t5, t6, t7, t8, t9)) {
  let f = fn(tup) {
    let #(t1, #(t2, #(t3, #(t4, #(t5, #(t6, #(t7, #(t8, t9)))))))) = tup
    #(t1, t2, t3, t4, t5, t6, t7, t8, t9)
  }

  both(
    t1,
    both(t2, both(t3, both(t4, both(t5, both(t6, both(t7, both(t8, t9))))))),
  )
  |> map(f)
}

//
// Utils
//

pub fn curry2(f: fn(x1, x2) -> y) -> fn(x1) -> fn(x2) -> y {
  fn(x1) { fn(x2) { f(x1, x2) } }
}

pub fn curry3(f: fn(x1, x2, x3) -> y) -> fn(x1) -> fn(x2) -> fn(x3) -> y {
  fn(x1) { fn(x2) { fn(x3) { f(x1, x2, x3) } } }
}

pub fn curry4(
  f: fn(x1, x2, x3, x4) -> y,
) -> fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> y {
  fn(x1) { fn(x2) { fn(x3) { fn(x4) { f(x1, x2, x3, x4) } } } }
}

pub fn curry5(
  f: fn(x1, x2, x3, x4, x5) -> y,
) -> fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> y {
  fn(x1) { fn(x2) { fn(x3) { fn(x4) { fn(x5) { f(x1, x2, x3, x4, x5) } } } } }
}

pub fn curry6(
  f: fn(x1, x2, x3, x4, x5, x6) -> y,
) -> fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> fn(x6) -> y {
  fn(x1) {
    fn(x2) {
      fn(x3) { fn(x4) { fn(x5) { fn(x6) { f(x1, x2, x3, x4, x5, x6) } } } }
    }
  }
}

pub fn curry7(
  f: fn(x1, x2, x3, x4, x5, x6, x7) -> y,
) -> fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> fn(x6) -> fn(x7) -> y {
  fn(x1) {
    fn(x2) {
      fn(x3) {
        fn(x4) {
          fn(x5) { fn(x6) { fn(x7) { f(x1, x2, x3, x4, x5, x6, x7) } } }
        }
      }
    }
  }
}

pub fn curry8(
  f: fn(x1, x2, x3, x4, x5, x6, x7, x8) -> y,
) -> fn(x1) ->
  fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> fn(x6) -> fn(x7) -> fn(x8) -> y {
  fn(x1) {
    fn(x2) {
      fn(x3) {
        fn(x4) {
          fn(x5) {
            fn(x6) { fn(x7) { fn(x8) { f(x1, x2, x3, x4, x5, x6, x7, x8) } } }
          }
        }
      }
    }
  }
}

pub fn curry9(
  f: fn(x1, x2, x3, x4, x5, x6, x7, x8, x9) -> y,
) -> fn(x1) ->
  fn(x2) ->
    fn(x3) -> fn(x4) -> fn(x5) -> fn(x6) -> fn(x7) -> fn(x8) -> fn(x9) -> y {
  fn(x1) {
    fn(x2) {
      fn(x3) {
        fn(x4) {
          fn(x5) {
            fn(x6) {
              fn(x7) {
                fn(x8) { fn(x9) { f(x1, x2, x3, x4, x5, x6, x7, x8, x9) } }
              }
            }
          }
        }
      }
    }
  }
}
