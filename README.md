# or_error

Proof of concept implementation of Jane Street's [Or_error](https://ocaml.org/p/base/v0.16.3/doc/Base/Or_error/index.html) for Gleam.

## Example

Imagine you have some code to get environment variables.

```gleam
// This is a function to spoof getting environment variables.
fn get_env(env_var: String) -> OrError(String) {
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

// Helper function that takes `OrError` values (a.k.a., `Result`s).
fn make_env_info(user user, home home, shell shell) {
  // We use return_curry3 to both curry the `EnvInfo` function, and lift it into
  // the OrError.
  or_error.return_curry3(EnvInfo)
  // Then we apply the lifted function to the arguments.
  |> or_error.apply(user)
  |> or_error.apply(home)
  |> or_error.apply(shell)
}

// EnvInfo as a string
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
pub fn example_ok_test() {
  make_env_info(
    user: get_env("USER"),
    home: get_env("HOME"),
    shell: get_env("SHELL"),
  )
  |> or_error.tag("getting environment variables")
  |> or_error.to_string(env_info_to_string)
  |> should.equal("Ok: USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
}

pub fn example_error_test() {
  make_env_info(
    user: get_env("apple"),
    home: get_env("HOME"),
    shell: get_env("pie"),
  )
  // This tag will be to add context
  |> or_error.tag("getting environment variables")
  |> or_error.to_string(env_info_to_string)
  // You can see all the errors are collected.
  |> should.equal(
    "Error: getting environment variables: 'apple' is not set; 'pie' is not set",
  )
}
```

That `or_error.tag` is optional, but it can be nice to add additional context to any potential failures, especially if they are bubbling up from deep in your application.

This is the applicative style error handling.[^1]  It is convenient when you need to perform multiple operations that may fail, and those operations are not related.  Note that the `OrError` type and its operations also can be used as a functor and monad as well.

## Notes

- It's using gleam/json v2, so requires Erlang OTP 27.
- Unlike OCaml's `Or_error`, in this library the Error message is not lazy.[^2]

## License

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/gleam_qcheck)

Copyright (c) 2024 Ryan M. Moore

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.

[^1]: Unfortunately, (or fortunately, depending on your point of view), Gleam does not support custom infix operators or currying by default, so you can't write it in the more natural style, e.g., `EnvInfo <$> user <*> home <*> shell`.
[^2]: I tried out a version with the lazy messages, but it was fairly annoying to use as Gleam doesn't give you a way to do the internal mutability required for a pleasant lazy type without using FFI, as far as I can tell.  It might be something worth revisiting later.
