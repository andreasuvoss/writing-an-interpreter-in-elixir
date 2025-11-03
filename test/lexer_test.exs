defmodule LexerTest do
  alias Lexer.Token
  alias Lexer.Lexer
  use ExUnit.Case

  @tag disabled: true
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
    let x = "hello";
    "foo bar";
    "foobar";
    ["test", 5];
    {"name": "Jimmy", "age": 81, "alive": true, "band": "Led Zeppelin"};
    """

    tests = [
      %Token{type: :let, literal: "let"},
      %Token{type: :ident, literal: "five"},
      %Token{type: :assign, literal: "="},
      %Token{type: :int, literal: "5"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :let, literal: "let"},
      %Token{type: :ident, literal: "ten"},
      %Token{type: :assign, literal: "="},
      %Token{type: :int, literal: "10"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :let, literal: "let"},
      %Token{type: :ident, literal: "add"},
      %Token{type: :assign, literal: "="},
      %Token{type: :function, literal: "fn"},
      %Token{type: :lparen, literal: "("},
      %Token{type: :ident, literal: "x"},
      %Token{type: :comma, literal: ","},
      %Token{type: :ident, literal: "y"},
      %Token{type: :rparen, literal: ")"},
      %Token{type: :lbrace, literal: "{"},
      %Token{type: :ident, literal: "x"},
      %Token{type: :plus, literal: "+"},
      %Token{type: :ident, literal: "y"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :rbrace, literal: "}"},
      %Token{type: :let, literal: "let"},
      %Token{type: :ident, literal: "result"},
      %Token{type: :assign, literal: "="},
      %Token{type: :ident, literal: "add"},
      %Token{type: :lparen, literal: "("},
      %Token{type: :ident, literal: "five"},
      %Token{type: :comma, literal: ","},
      %Token{type: :ident, literal: "ten"},
      %Token{type: :rparen, literal: ")"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :bang, literal: "!"},
      %Token{type: :minus, literal: "-"},
      %Token{type: :slash, literal: "/"},
      %Token{type: :asterix, literal: "*"},
      %Token{type: :int, literal: "5"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :int, literal: "5"},
      %Token{type: :lt, literal: "<"},
      %Token{type: :int, literal: "10"},
      %Token{type: :gt, literal: ">"},
      %Token{type: :int, literal: "5"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :if, literal: "if"},
      %Token{type: :lparen, literal: "("},
      %Token{type: :int, literal: "5"},
      %Token{type: :lt, literal: "<"},
      %Token{type: :int, literal: "10"},
      %Token{type: :rparen, literal: ")"},
      %Token{type: :lbrace, literal: "{"},
      %Token{type: :return, literal: "return"},
      %Token{type: true, literal: "true"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :rbrace, literal: "}"},
      %Token{type: :else, literal: "else"},
      %Token{type: :lbrace, literal: "{"},
      %Token{type: :return, literal: "return"},
      %Token{type: false, literal: "false"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :rbrace, literal: "}"},
      %Token{type: :int, literal: "10"},
      %Token{type: :eq, literal: "=="},
      %Token{type: :int, literal: "10"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :int, literal: "10"},
      %Token{type: :not_eq, literal: "!="},
      %Token{type: :int, literal: "9"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :let, literal: "let"},
      %Token{type: :ident, literal: "x"},
      %Token{type: :assign, literal: "="},
      %Token{type: :string, literal: "hello"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :string, literal: "foo bar"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :string, literal: "foobar"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :lbracket, literal: "["},
      %Token{type: :string, literal: "test"},
      %Token{type: :comma, literal: ","},
      %Token{type: :int, literal: "5"},
      %Token{type: :rbracket, literal: "]"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :lbrace, literal: "{"},
      %Token{type: :string, literal: "name"},
      %Token{type: :colon, literal: ":"},
      %Token{type: :string, literal: "Jimmy"},
      %Token{type: :comma, literal: ","},
      %Token{type: :string, literal: "age"},
      %Token{type: :colon, literal: ":"},
      %Token{type: :int, literal: "81"},
      %Token{type: :comma, literal: ","},
      %Token{type: :string, literal: "alive"},
      %Token{type: :colon, literal: ":"},
      %Token{type: :true, literal: "true"},
      %Token{type: :comma, literal: ","},
      %Token{type: :string, literal: "band"},
      %Token{type: :colon, literal: ":"},
      %Token{type: :string, literal: "Led Zeppelin"},
      %Token{type: :rbrace, literal: "}"},
      %Token{type: :semicolon, literal: ";"},
      %Token{type: :eof, literal: ""}
    ]

    #    {"name": "Jimmy", "age": 81, "alive": true, "band": "Led Zeppelin"};

    assert Lexer.tokenize(input) == tests
  end

end
