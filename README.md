# Writing An Interpreter In Elixir

This is my attempt at going through the book 'Writing An Interpreter In Go' by Thorsten Ball. However instead of doing
it in Go, I am attempting to do it in Elixir while following the strategies from the book.

## Start the interactive interpreter
At this point in time the REPL doesn't do much, but you can start it by running the following command from the
repository's root directory

```sh
mix run
```
It just runs the lexer and prints out each token for a given input.

```
Hello andreasvoss! This is the Monkey programming language!
Feel free to  type in commands (:q to quit)

>> 1+3
%Lexer.Token{type: :int, literal: "1"}
%Lexer.Token{type: :plus, literal: "+"}
%Lexer.Token{type: :int, literal: "3"}
%Lexer.Token{type: :eof, literal: ""}
```

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
