defmodule InterpreterTest do
  alias Parser.InfixExpression
  alias Parser.Identifier
  alias Lexer.Token
  alias Lexer.Lexer
  use ExUnit.Case
  doctest Interpreter

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
      %Token{type: :eof, literal: ""}
    ]

    assert Lexer.tokenize(input) == tests
  end

  @tag disabled: true
  test "let statements" do
    input = """
    let x = 5;
    let y = 10;
    let foobar = 838383;
    """

    # input = """
    # let x =;
    # let y = ;
    # let foobar = ;
    # """

    tokens = Lexer.tokenize(input)

    # IO.inspect(tokens)

    # {parsed, tokens} = Parser.Parser.parse(tokens)

    program = Parser.Parser.parse_program(tokens)

    # IO.inspect(program)

    tests = [
      "x",
      "y",
      "foobar"
    ]

    # IO.inspect(program)

    assert length(program.statements) == 3

    Enum.zip(program.statements, tests)
    |> Enum.each(fn {statement, expected} ->
      # assert statement |> Parser.Statement.token_literal() == "let"
      assert statement.token.type == :let
      assert statement.name.value == expected
    end)
  end

  @tag disabled: true
  test "return statements" do
    input = """
      return 5;
      return 10;
      return 993322;
    """

    # input = """
    #   return ;
    #   return ;
    #   return ;
    # """

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    # IO.inspect(program)

    tests = [
      "5",
      "10",
      "993322"
    ]

    assert length(program.statements) == 3

    Enum.zip(program.statements, tests)
    |> Enum.each(fn {statement, _} ->
      assert statement |> Parser.Statement.token_literal() == "return"
      assert statement.token.type == :return
    end)
  end

  @tag disabled: true
  test "stringify program" do
    # input = """
    #   let myVar = anotherVar;
    # """
    #
    # tokens = Lexer.tokenize(input)
    #
    # program = Parser.Parser.parse_program(tokens)

    program = %Parser.Program{
      statements: [
        %Parser.LetStatement{
          token: %Token{type: :let, literal: "let"},
          name: %Parser.Identifier{
            token: %Token{type: :ident, literal: "myVar"},
            value: "myVar"
          },
          value: %Parser.Identifier{
            token: %Token{type: :ident, literal: "anotherVar"},
            value: "anotherVar"
          }
        }
      ]
    }

    # program_string = to_string(program)

    assert "#{program}" == "let myVar = anotherVar;"
  end

  @tag disabled: true
  test "identifier expression" do
    input = "foobar;"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    # defstruct token: %Lexer.Token{type: :expression, literal: nil}, expression: ""

    # infix_functions = %{function: fn x -> "#{x}" end}
    #
    # test_func = infix_functions.function.("lol")
    #
    #
    # IO.puts(test_func)

    # IO.inspect(tokens)
    IO.inspect(program)

    assert length(program.statements) == 1

    # IO.inspect(program)

    expression = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = expression

    assert %Parser.Identifier{token: %Token{type: :ident, literal: "foobar"}, value: "foobar"} =
             expression.expression

    # assert "#{program}" == "let myVar = anotherVar;"
  end

  @tag disabled: true
  test "integer expression" do
    input = "5;"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    # IO.inspect(tokens)
    # IO.inspect(program)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.IntegerLiteral{token: %Token{type: :int, literal: "5"}, value: 5} =
             statement.expression

    # assert "#{program}" == "let myVar = anotherVar;"
  end

  @tag disabled: true
  test "prefix bang" do
    input = "!5;"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    # IO.inspect(tokens)
    # IO.inspect(program)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement
    assert %Parser.PrefixExpression{} = statement.expression

    assert %Parser.PrefixExpression{
             token: %Token{type: :bang},
             operator: "!",
             right: %Parser.IntegerLiteral{}
           } = statement.expression

    # assert "#{program}" == "let myVar = anotherVar;"
  end

  @tag disabled: true
  test "prefix minus" do
    input = "-5;"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.PrefixExpression{
             token: %Token{type: :minus},
             operator: "-",
             right: %Parser.IntegerLiteral{}
           } = statement.expression

    # assert "#{program}" == "let myVar = anotherVar;"
  end

  @tag disabled: true
  test "infix plus" do
    input = "5 + 5;"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    # IO.inspect(program)

    # IO.puts(program)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.InfixExpression{
             token: %Token{type: :plus},
             operator: "+",
             left: %Parser.IntegerLiteral{},
             right: %Parser.IntegerLiteral{}
           } = statement.expression

    # assert "#{program}" == "let myVar = anotherVar;"
  end

  @tag disabled: true
  test "precedence" do
    tests = [
      %{input: "-a * b", expected: "((-a) * b)"},
      %{input: "!-a", expected: "(!(-a))"},
      %{input: "a + b + c", expected: "((a + b) + c)"},
      %{input: "a + b - c", expected: "((a + b) - c)"},
      %{input: "a * b * c", expected: "((a * b) * c)"},
      %{input: "a * b / c", expected: "((a * b) / c)"},
      %{input: "a + b / c", expected: "(a + (b / c))"},
      %{input: "a + b * c + d / e - f", expected: "(((a + (b * c)) + (d / e)) - f)"},
      %{input: "3 + 4; -5 * 5", expected: "(3 + 4)((-5) * 5)"},
      %{input: "5 > 4 == 3 < 4", expected: "((5 > 4) == (3 < 4))"},
      %{input: "5 > 4 != 3 < 4", expected: "((5 > 4) != (3 < 4))"},
      %{input: "3 + 4 * 5 == 3 * 1 + 4 * 5", expected: "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"},
      %{input: "true", expected: "true"},
      %{input: "false", expected: "false"},
      %{input: "3 > 5 == false", expected: "((3 > 5) == false)"},
      %{input: "3 < 5 == true", expected: "((3 < 5) == true)"},
      %{input: "1 + (2 + 3) + 4", expected: "((1 + (2 + 3)) + 4)"},
      %{input: "(5 + 5) * 2", expected: "((5 + 5) * 2)"},
      %{input: "2 / (5 + 5)", expected: "(2 / (5 + 5))"},
      %{input: "-(5 + 5)", expected: "(-(5 + 5))"},
      %{input: "!(true == true)", expected: "(!(true == true))"}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      program = Parser.Parser.parse_program(tokens)

      assert "#{program}" == test.expected
    end)
  end

  @tag disabled: true
  test "true boolean expression" do
    input = "true;"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.Boolean{token: %Token{type: true, literal: "true"}, value: true} =
             statement.expression
  end

  @tag disabled: true
  test "false boolean expression" do
    input = "false;"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.Boolean{token: %Token{type: false, literal: "false"}, value: false} =
             statement.expression
  end

  @tag disabled: true
  test "let statement true boolean expression" do
    input = "let foobar = true;"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.LetStatement{} = statement

    assert %Parser.Boolean{token: %Token{type: true, literal: "true"}, value: true} =
             statement.value
  end

  @tag disabled: true
  test "if expression" do
    input = "if (x < y) { x }"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.IfExpression{
             consequence: %Parser.BlockStatement{
               statements: [%Parser.ExpressionStatement{expression: %Identifier{value: "x"}}]
             },
             alternative: nil
           } = statement.expression
  end

  @tag disabled: true
  test "if else expression" do
    input = "if (x < y) { x } else { y }"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.IfExpression{
             consequence: %Parser.BlockStatement{
               statements: [%Parser.ExpressionStatement{expression: %Identifier{value: "x"}}]
             },
             alternative: %Parser.BlockStatement{
               statements: [%Parser.ExpressionStatement{expression: %Identifier{value: "y"}}]
             }
           } = statement.expression
  end

  @tag disabled: true
  test "function literal" do
    input = "fn(x, y) { x + y }"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert length(statement.expression.parameters) == 2
    assert length(statement.expression.body.statements) == 1

    assert %Parser.FunctionLiteral{
             body: %Parser.BlockStatement{
               statements: [
                 %Parser.ExpressionStatement{
                   expression: %InfixExpression{
                     left: %Identifier{value: "x"},
                     right: %Identifier{value: "y"},
                     operator: "+"
                   }
                 }
               ]
             },
             parameters: [%Identifier{value: "x"}, %Identifier{value: "y"}]
           } = statement.expression
  end

  @tag disabled: true
  test "function literal single parameter" do
    input = "fn(x) { x }"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert length(statement.expression.parameters) == 1
    assert length(statement.expression.body.statements) == 1

    assert %Parser.FunctionLiteral{
             body: %Parser.BlockStatement{
               statements: [
                 %Parser.ExpressionStatement{
                   expression: %Identifier{value: "x"}
                 }
               ]
             },
             parameters: [%Identifier{value: "x"}]
           } = statement.expression
  end

  @tag disabled: true
  test "function literal no parameters" do
    input = "fn() { x + y }"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert length(statement.expression.parameters) == 0
    assert length(statement.expression.body.statements) == 1

    assert %Parser.FunctionLiteral{
             body: %Parser.BlockStatement{
               statements: [
                 %Parser.ExpressionStatement{
                   expression: %InfixExpression{
                     left: %Identifier{value: "x"},
                     right: %Identifier{value: "y"},
                     operator: "+"
                   }
                 }
               ]
             },
             parameters: []
           } = statement.expression
  end

  @tag disabled: true
  test "function literal no parameters and empty body" do
    input = "fn() { }"

    tokens = Lexer.tokenize(input)

    program = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert length(statement.expression.parameters) == 0
    assert length(statement.expression.body.statements) == 0

    assert %Parser.FunctionLiteral{
             body: %Parser.BlockStatement{
               statements: []
             },
             parameters: []
           } = statement.expression
  end
end
