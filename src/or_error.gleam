import gleam/result
import or_error/error.{type Error}

// Note: on all the funN functions, we go up to N=9 because that is what the
// gleam/dynamic module does.  And those are what you often want to use with the
// applicative style error handling.

pub type OrError(a) =
  Result(a, Error)

pub fn tag(ta: OrError(a), tag tag: String) -> OrError(a) {
  result.map_error(ta, error.tag(_, tag))
}

pub fn error_string(msg: String) -> OrError(a) {
  Error(error.of_string(msg))
}

pub fn to_string(ta: OrError(a), a_to_string: fn(a) -> String) -> String {
  case ta {
    Ok(a) -> a_to_string(a)
    Error(error) -> error.to_string(error)
  }
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
    Error(e1), Error(e2) -> Error(error.of_list([e1, e2]))
  }
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

//
// Utils
//

fn curry2(f: fn(x1, x2) -> y) -> fn(x1) -> fn(x2) -> y {
  fn(x1) { fn(x2) { f(x1, x2) } }
}

fn curry3(f: fn(x1, x2, x3) -> y) -> fn(x1) -> fn(x2) -> fn(x3) -> y {
  fn(x1) { fn(x2) { fn(x3) { f(x1, x2, x3) } } }
}

fn curry4(
  f: fn(x1, x2, x3, x4) -> y,
) -> fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> y {
  fn(x1) { fn(x2) { fn(x3) { fn(x4) { f(x1, x2, x3, x4) } } } }
}

fn curry5(
  f: fn(x1, x2, x3, x4, x5) -> y,
) -> fn(x1) -> fn(x2) -> fn(x3) -> fn(x4) -> fn(x5) -> y {
  fn(x1) { fn(x2) { fn(x3) { fn(x4) { fn(x5) { f(x1, x2, x3, x4, x5) } } } } }
}

fn curry6(
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
