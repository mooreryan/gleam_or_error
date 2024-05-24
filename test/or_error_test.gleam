import gleeunit
import gleeunit/should
import or_error.{type OrError}

pub fn main() {
  gleeunit.main()
}

fn get_env(env_var: String) -> OrError(String) {
  // This is a function to spoof getting environment variables.
  case env_var {
    "USER" -> or_error.return("ryan")
    "HOME" -> or_error.return("/home/ryan")
    "SHELL" -> or_error.return("/bin/bash")
    var_name -> or_error.error_string("'" <> var_name <> "' is not set")
  }
}

type EnvInfo {
  EnvInfo(user: String, home: String, shell: String)
}

fn make_env_info(user user, home home, shell shell) {
  EnvInfo
  |> or_error.return_curry3
  |> or_error.apply(user)
  |> or_error.apply(home)
  |> or_error.apply(shell)
}

// This one is for use with `or_error.both`.
fn make_env_info_tup(tup) {
  let #(user, #(home, shell)) = tup
  EnvInfo(user: user, home: home, shell: shell)
}

fn env_info_to_string(env_info: EnvInfo) -> String {
  "USER: "
  <> env_info.user
  <> "; HOME: "
  <> env_info.home
  <> "; SHELL: "
  <> env_info.shell
}

pub fn or_error_both_f__test() {
  {
    use <- or_error.both_(get_env("USER"))
    use <- or_error.both_(get_env("HOME"))
    get_env("SHELL")
  }
  |> or_error.map(make_env_info_tup)
  |> or_error.to_string(env_info_to_string)
  |> should.equal("USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
}

pub fn or_error_both_f__2__test() {
  let result =
    {
      use <- or_error.both_(get_env("apple"))
      use <- or_error.both_(get_env("USER"))
      get_env("cherry")
    }
    |> or_error.map(make_env_info_tup)

  result
  |> or_error.to_string(env_info_to_string)
  |> should.equal("'apple' is not set; 'cherry' is not set")
}

pub fn tuple_n__test() {
  or_error.tuple3(get_env("USER"), get_env("HOME"), get_env("SHELL"))
  |> or_error.map(fn(tup) {
    let #(user, home, shell) = tup
    EnvInfo(user: user, home: home, shell: shell)
  })
  |> or_error.to_string(env_info_to_string)
  |> should.equal("USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
}

pub fn or_error_apply__ok_2__test() {
  make_env_info(
    user: get_env("USER"),
    home: get_env("HOME"),
    shell: get_env("SHELL"),
  )
  |> or_error.tag("getting environment variables")
  |> or_error.to_string(env_info_to_string)
  |> should.equal("USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
}

pub fn or_error_apply__error_2__test() {
  make_env_info(
    user: get_env("apple"),
    home: get_env("HOME"),
    shell: get_env("pie"),
  )
  |> or_error.tag("getting environment variables")
  |> or_error.to_string(env_info_to_string)
  |> should.equal(
    "getting environment variables: 'apple' is not set; 'pie' is not set",
  )
}
