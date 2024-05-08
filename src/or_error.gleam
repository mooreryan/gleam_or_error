import gleam/result
import or_error/error.{type Error}

pub type OrError(a) =
  Result(a, Error)

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

pub fn both(ta: OrError(a), tb: OrError(b)) -> OrError(#(a, b)) {
  map2(ta, tb, fn(a, b) { #(a, b) })
}

// This is just an example so you can use the `use` style.  This is odd though.
pub fn both_f(ta: OrError(a), f: fn() -> OrError(b)) -> OrError(#(a, b)) {
  map2(ta, f(), fn(a, b) { #(a, b) })
}

pub fn apply(tf: OrError(fn(a) -> b), ta: OrError(a)) -> OrError(b) {
  map2(tf, ta, fn(f, a) { f(a) })
}

pub fn return(a: a) -> OrError(a) {
  Ok(a)
}

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
