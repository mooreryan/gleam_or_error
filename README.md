# or_error

Proof of concept implementation of Jane Street's [Or_error](https://ocaml.org/p/base/v0.16.3/doc/Base/Or_error/index.html) for Gleam.

You will notice many things missing compared to the linked docs including pleasant serialization and lazy message creation.

However, it does allow an applicative style of error handling, where you can run all your `OrError` producing functions and get back all errors that were generated.  


## Example

Imagine you have some code to get environment variables.

```gleam
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
```

Then you could imagine some code like this to actually attempt to get some variables from the environment.

```gleam
pub fn example1() {
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

pub fn example2() {
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
```

That `or_error.tag` is optional, but it can be nice if you are passing around an `OrError` and it could fail in multiple contexts.

You could also use the `or_error.both` style if you prefer, but that isn't quite as pleasant without the syntax support that OCaml has (e.g., the `let%bind ... and` seen in [ppx_let](https://github.com/janestreet/ppx_let?tab=readme-ov-file#syntactic-forms-and-actual-rewriting).)

## Acknowledgements

Very heavily inspired by the `Or_error` module from Jane Street's [Base](https://github.com/janestreet/base) package.

## License

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/gleam_qcheck)

Copyright (c) 2024 Ryan M. Moore

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.
