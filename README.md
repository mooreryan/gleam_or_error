# or_error

A specialization of the [result](https://hexdocs.pm/gleam_stdlib/gleam/result.html) type where the `Error` constructor carries a value of type `Error`.  It provides many of the same functions as the `result` module from the standard library, plus some additional ones that make use of the specific error type (as well as dropping a few that don't make sense with this error type).

`OrError` provides the applicative style error handling.  It is convenient when you need to perform multiple operations that may fail, and those operations are not related.  The `OrError` type and its operations also can be used as a functor and monad as well.

## Example

### Using `use`

Gleam provides the use [use](https://tour.gleam.run/advanced-features/use/) construct to make it easy to work with functions in the final position of an argument list. Let's see how we can use the `OrError` type with `use`.

```gleam
import gleeunit/should
import or_error.{type OrError}

// This is a function to spoof getting environment variables.  You could imagine 
// a real function that interacts with the user's environment.
fn get_env(env_var: String) -> OrError(String) {
  case env_var {
    "USER" -> or_error.return("ryan")
    "HOME" -> or_error.return("/home/ryan")
    "SHELL" -> or_error.return("/bin/bash")
    var_name -> or_error.error_string("'" <> var_name <> "' is not set")
  }
}

// A type to store some environment variables.
type EnvInfo {
  EnvInfo(user: String, home: String, shell: String)
}

// For viewing environment info as a string.
fn env_info_to_string(env_info: EnvInfo) -> String {
  "USER: "
  <> env_info.user
  <> "; HOME: "
  <> env_info.home
  <> "; SHELL: "
  <> env_info.shell
}

pub fn map_with_use__ok__test() {
  // Try to construct a value of type `EnvInfo`.  This one will be Ok.
  let env_info = {
    use user, home, shell <- or_error.map3(
      get_env("USER"),
      get_env("HOME"),
      get_env("SHELL"),
    )
    EnvInfo(user: user, home: home, shell: shell)
  }

  env_info
  // You can add a tag here to add more context in case of failures.
  |> or_error.tag("getting environment variables")
  |> or_error.to_string(env_info_to_string)
  |> should.equal("Ok: USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
}

pub fn map_with_use__error__test() {
  // This time it will fail, because `apple` and `pie` are not set in the user's 
  // environment (or at least in our fake env variable function).
  let env_info = {
    use user, home, shell <- or_error.map3(
      get_env("apple"),
      get_env("HOME"),
      get_env("pie"),
    )
    EnvInfo(user: user, home: home, shell: shell)
  }

  env_info
  |> or_error.tag("getting environment variables")
  |> or_error.to_string(env_info_to_string)
  // Look at how all the errors are collected and displayed in a nice way!
  |> should.equal(
    "Error: getting environment variables: 'apple' is not set; 'pie' is not set",
  )
}
```

That `or_error.tag` is optional, but it can be nice to add additional context to any potential failures, especially if they are bubbling up from deep in your application.

For comparison, the `map3` could be written without `use` like this:

```gleam
or_error.map3(get_env("USER"), get_env("HOME"), get_env("SHELL"), EnvInfo)
|> or_error.tag("getting environment variables")
|> or_error.to_string(env_info_to_string)
|> should.equal("Ok: USER: ryan; HOME: /home/ryan; SHELL: /bin/bash")
```

That might be more clear in this case.  The only thing to watch out for is if you are familiar with other functional languages, you may expect the mapping function to be the first argument rather than the last.  Putting as the last argument allows you to use `use` when you feel it is appropriate to do so.

### Applicative style

Keeping with the same example as above, let's look at the applicative style.  Either of these ways will work the same.

```gleam
// You could do it like this:
or_error.return_curry3(EnvInfo)
|> or_error.apply(get_env("USER"))
|> or_error.apply(get_env("HOME"))
|> or_error.apply(get_env("SHELL"))
|> or_error.tag("getting environment variables")

// Or like this:
or_error.map(get_env("USER"), curry3(EnvInfo)) 
|> apply(get_env("HOME")) |> apply(get_env("SHELL"))
```

In the first way, we use `return_curry3` to both curry the `EnvInfo` function, and lift it into the `OrError` structure. Then we `apply` the lifted function to its arguments.  

The second way is a slightly different way of writing basically the same thing.  In fact, `map3` and above are implemented in this way.

Now, I would probably prefer to use the `mapN` functions (with or without `use` as appropriate) than to use the `return`+`apply` functions.  I think that way is a bit more natural in Gleam since Gleam does not support custom infix operators, nor does is have curried functions by default.[^1]  

## Notes

- It's using gleam/json v2, so requires Erlang OTP 27.
- This is essentially an implementation of Jane Street's [Or_error](https://ocaml.org/p/base/v0.16.3/doc/Base/Or_error/index.html) for Gleam.
  - Unlike OCaml's `Or_error`, in this library the Error message is not lazy.[^2]

## License

[![license MIT or Apache
2.0](https://img.shields.io/badge/license-MIT%20or%20Apache%202.0-blue)](https://github.com/mooreryan/gleam_qcheck)

Copyright (c) 2024 Ryan M. Moore

Licensed under the Apache License, Version 2.0 or the MIT license, at your option. This program may not be copied, modified, or distributed except according to those terms.

[^1]: Unfortunately (or maybe fortunately depending on your point of view), this means you can't write the above example in the more pleasant style, e.g., `EnvInfo <$> user <*> home <*> shell`, where `<$>` is map and `<*>` is apply.
[^2]: I tried out a version with the lazy messages, but the API was not pleasant to use as Gleam doesn't give you a way to do the internal mutability required for a nice lazy type without using FFI, as far as I can tell.  It might be something worth revisiting later.
