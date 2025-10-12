defmodule InterpreterTest do
  alias InterpreterTest.Lol
  alias Lexer.Token
  alias Lexer.Lexer
  use ExUnit.Case
  doctest Interpreter

  test "lexer should tokenize input" do
    input = """
    let five = 5;
    let ten = 10;
    let add = fn(x, y) {
      x + y;
    }

    let result = add(five, ten);

    !-/*5;
    5 < 10 > 5;

    if (5 < 10) {
      return true;
    } else {
      return false;
    }

    10 == 10;
    10 != 9;
    """

    tests = [
      %{type: :let, literal: "let"},
      %{type: :ident, literal: "five"},
      %{type: :assign, literal: "="},
      %{type: :int, literal: "5"},
      %{type: :semicolon, literal: ";"},
      %{type: :let, literal: "let"},
      %{type: :ident, literal: "ten"},
      %{type: :assign, literal: "="},
      %{type: :int, literal: "10"},
      %{type: :semicolon, literal: ";"},
      %{type: :let, literal: "let"},
      %{type: :ident, literal: "add"},
      %{type: :assign, literal: "="},
      %{type: :function, literal: "fn"},
      %{type: :lparen, literal: "("},
      %{type: :ident, literal: "x"},
      %{type: :comma, literal: ","},
      %{type: :ident, literal: "y"},
      %{type: :rparen, literal: ")"},
      %{type: :lbrace, literal: "{"},
      %{type: :ident, literal: "x"},
      %{type: :plus, literal: "+"},
      %{type: :ident, literal: "y"},
      %{type: :semicolon, literal: ";"},
      %{type: :rbrace, literal: "}"},
      %{type: :let, literal: "let"},
      %{type: :ident, literal: "result"},
      %{type: :assign, literal: "="},
      %{type: :ident, literal: "add"},
      %{type: :lparen, literal: "("},
      %{type: :ident, literal: "five"},
      %{type: :comma, literal: ","},
      %{type: :ident, literal: "ten"},
      %{type: :rparen, literal: ")"},
      %{type: :semicolon, literal: ";"},
      %{type: :bang, literal: "!"},
      %{type: :minus, literal: "-"},
      %{type: :slash, literal: "/"},
      %{type: :asterix, literal: "*"},
      %{type: :int, literal: "5"},
      %{type: :semicolon, literal: ";"},
      %{type: :int, literal: "5"},
      %{type: :lt, literal: "<"},
      %{type: :int, literal: "10"},
      %{type: :gt, literal: ">"},
      %{type: :int, literal: "5"},
      %{type: :semicolon, literal: ";"},
      %{type: :if, literal: "if"},
      %{type: :lparen, literal: "("},
      %{type: :int, literal: "5"},
      %{type: :lt, literal: "<"},
      %{type: :int, literal: "10"},
      %{type: :rparen, literal: ")"},
      %{type: :lbrace, literal: "{"},
      %{type: :return, literal: "return"},
      %{type: true, literal: "true"},
      %{type: :semicolon, literal: ";"},
      %{type: :rbrace, literal: "}"},
      %{type: :else, literal: "else"},
      %{type: :lbrace, literal: "{"},
      %{type: :return, literal: "return"},
      %{type: false, literal: "false"},
      %{type: :semicolon, literal: ";"},
      %{type: :rbrace, literal: "}"},
      %{type: :int, literal: "10"},
      %{type: :eq, literal: "=="},
      %{type: :int, literal: "10"},
      %{type: :semicolon, literal: ";"},
      %{type: :int, literal: "10"},
      %{type: :not_eq, literal: "!="},
      %{type: :int, literal: "9"},
      %{type: :semicolon, literal: ";"},
      %{type: :eof, literal: ""}
    ]

    assert Lexer.tokenize(input) == tests
  end
end
