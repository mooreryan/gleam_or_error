import gleam/function
import gleeunit
import gleeunit/should
import or_error.{type OrError}

pub fn main() {
  gleeunit.main()
}

fn get_env(env_var: String) -> OrError(String) {
  // This is a function to spoof getting environment variables.
  case env_var {
    "HOME" -> or_error.return("/home/ryan")
    "USER" -> or_error.return("ryan")
    "SHELL" -> or_error.return("/bin/bash")
    var_name -> or_error.error_string("'" <> var_name <> "' is not set")
  }
}

type EnvInfo {
  EnvInfo(user: String, home: String, shell: String)
}

fn make_env_info(user user, home home, shell shell) {
  EnvInfo(user, home, shell)
}

fn env_info_to_string(env_info: EnvInfo) -> String {
  "USER: "
  <> env_info.user
  <> "; HOME: "
  <> env_info.home
  <> "; SHELL: "
  <> env_info.shell
}

pub fn or_error_both__test() {
  let result_a =
    get_env("USER")
    |> or_error.both(
      get_env("HOME")
      |> or_error.both(get_env("SHELL")),
    )
    |> or_error.map(fn(tup) {
      let #(home, #(user, shell)) = tup

      EnvInfo(home, user, shell)
    })

  let result_b =
    or_error.both(
      get_env("USER"),
      or_error.both(get_env("HOME"), get_env("SHELL")),
    )
    |> or_error.map(fn(tup) {
      let #(home, #(user, shell)) = tup

      EnvInfo(home, user, shell)
    })

  should.equal(result_a, result_b)

  result_a
  |> or_error.to_string(env_info_to_string)
  |> should.equal("USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
}

pub fn or_error_both_f__test() {
  {
    use <- or_error.both_f(get_env("USER"))
    use <- or_error.both_f(get_env("HOME"))
    get_env("SHELL")
  }
  |> or_error.map(fn(x) {
    let #(user, #(home, shell)) = x
    make_env_info(user, home, shell)
  })
  |> or_error.to_string(env_info_to_string)
  |> should.equal("USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
}

pub fn or_error_both_f__2__test() {
  let result =
    {
      use <- or_error.both_f(get_env("apple"))
      use <- or_error.both_f(get_env("USER"))
      get_env("cherry")
    }
    |> or_error.map(fn(x) {
      let #(user, #(home, shell)) = x
      make_env_info(user, home, shell)
    })

  result
  |> or_error.to_string(env_info_to_string)
  |> should.equal("'apple' is not set; 'cherry' is not set")
}

pub fn or_error_apply__ok__test() {
  let env_info =
    make_env_info
    |> function.curry3
    |> or_error.return
    |> or_error.apply(get_env("USER"))
    |> or_error.apply(get_env("HOME"))
    |> or_error.apply(get_env("SHELL"))
    |> or_error.tag("getting environment variables")

  env_info
  |> or_error.to_string(env_info_to_string)
  |> should.equal("USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
}

pub fn or_error_apply__error__test() {
  let env_info =
    make_env_info
    |> function.curry3
    |> or_error.return
    |> or_error.apply(get_env("apple"))
    |> or_error.apply(get_env("HOME"))
    |> or_error.apply(get_env("pie"))
    |> or_error.tag("getting environment variables")

  env_info
  |> or_error.to_string(env_info_to_string)
  |> should.equal(
    "getting environment variables: 'apple' is not set; 'pie' is not set",
  )
}
