# Writing An Interpreter In Elixir

This is my attempt at going through the book 'Writing An Interpreter In Go' by Thorsten Ball. However instead of doing
it in Go, I am attempting to do it in Elixir while following the strategies from the book.

## Start the interactive interpreter
You can run the REPL by running the following command from the repository's root directory

```sh
mix run
```
In its current form it runs the lexer, parser and evaluator which means you should be able to parse any Monkey program,
that uses the features implemented in this interpreter.

```
Hello andreasvoss! This is the Monkey programming language!
Feel free to type in commands (:q to quit)

>> let hello = fn(a, b, c) { a + b + c }
fn(a, b, c){
 ((a + b) + c)
}
>> hello(1, 2, 3)
6
```

I have added some error handling such that if you do make a mistake, the REPL should not crash on you, and you might get
a helpful error. I am making no promises on either though.

In case of a parser error you will get an error looking like this

```
Hello andreasvoss! This is the Monkey programming language!
Feel free to type in commands (:q to quit)

>> let x = 1; let y 1
     .-"-.            .-"-.            .-"-.           .-"-.
   _/_-.-_\_        _/.-.-.\_        _/.-.-.\_       _/.-.-.\_
  / __} {__ \      /|( o o )|\      ( ( o o ) )     ( ( o o ) )
 / //  "  \\ \    | //  "  \\ |      |/  "  \|       |/  "  \|
/ / \'---'/ \ \  / / \'---'/ \ \      \'/^\'/         \ .-. /
\ \_/`"""`\_/ /  \ \_/`"""`\_/ /      /`\ /`\         /`"""`\
 \           /    \           /      /  /|\  \       /       \

Woops! We ran into some monkey business here!
parser errors:
        1. expected '=' after let y
```

Whereas you will get another type of error if it occurs during evaluation

```
Hello andreasvoss! This is the Monkey programming language!
Feel free to type in commands (:q to quit)

>> 8 + true
type mismatch: INTEGER + BOOLEAN
```

## Implemented features

* Integers (`8`)
* Booleans (`true`)
* If-expressions (`if(true) {} else {}`)
* Functions (`fn(x){ x + 1 }`)
* Variable assignment (`let x = 1`)
* Optional semicolons
* Recursive functions
* Closures
* Strings (incl. builtin function `len(s)`)
* Arrays (incl. builtin functions `len(arr)`, `first(arr)`, `last(arr)`, `rest(arr)` and `push(arr, elem)`)
* Hashes (maps)

## Run tests
To run the tests the following command should be run. The `--no-start` flag makes sure only the tests run, if it's not
included the REPL will start, and the tests will not continue without manual intervention (`CTRL+C`).

```sh
mix test --no-start
```

In order to disable some tests -- which is really nice when debugging a single test -- the following command can be run,
which disables all tests with the `disabled` tag. Just make sure the test you are working on does not have that tag.

```sh
mix test --no-start --exclude disabled
```
