import gleam/list
import gleam/string

pub type Error {
  StringError(String)
  TaggedError(String, Error)
  ListError(List(Error))
}

pub fn of_string(msg: String) -> Error {
  StringError(msg)
}

pub fn of_list(errors: List(Error)) -> Error {
  ListError(errors)
}

pub fn tag(error: Error, tag tag: String) -> Error {
  TaggedError(tag, error)
}

pub fn to_string(error: Error) -> String {
  do_to_strings(error, [])
  |> string.join("")
}

fn do_to_strings(error: Error, acc: List(String)) -> List(String) {
  case error {
    StringError(msg) -> [msg, ..acc]
    TaggedError(tag, error) -> [tag, ": ", ..do_to_strings(error, acc)]
    ListError(errors) ->
      list.fold(list.reverse(errors), acc, fn(acc, error) {
        do_to_strings(error, case acc {
          [] -> acc
          _ -> ["; ", ..acc]
        })
      })
  }
}
