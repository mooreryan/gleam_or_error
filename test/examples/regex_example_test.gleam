import birdie
import gleam/int
import gleam/json
import gleam/list
import gleam/regex
import or_error

pub fn regex_example__ok__test() {
  {
    use numbers <- or_error.bind(
      regex.from_string("[0-9]+") |> or_error.from_result,
    )
    regex.scan(numbers, "apple 3, pie 47, gingerbread 8")
    |> list.map(fn(match) { int.parse(match.content) |> or_error.from_result })
    |> or_error.all
  }
  |> or_error.to_json(json.array(_, json.int))
  |> json.to_string
  |> birdie.snap("regex_exampe_test.regex_example__ok__test")
}

pub fn regex_example__error__test() {
  {
    use numbers <- or_error.bind(
      regex.from_string("[0-9+") |> or_error.from_result,
    )
    regex.scan(numbers, "apple 3, pie 47, gingerbread 8")
    |> list.map(fn(match) { int.parse(match.content) |> or_error.from_result })
    |> or_error.all
  }
  |> or_error.to_json(json.array(_, json.int))
  |> json.to_string
  |> birdie.snap("regex_exampe_test.regex_example__error__test")
}
