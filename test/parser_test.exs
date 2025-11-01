defmodule ParserTest do
  alias Parser.ArrayLiteral
  alias Parser.ExpressionStatement
  alias Parser.Boolean
  alias Parser.IntegerLiteral
  alias Parser.InfixExpression
  alias Parser.Identifier
  alias Lexer.Token
  alias Lexer.Lexer
  use ExUnit.Case

  @tag disabled: true
  test "let statements" do
    input = """
    let x = 5;
    let y = 10;
    let foobar = 838383;
    """

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

    tests = [
      "x",
      "y",
      "foobar"
    ]

    assert length(program.statements) == 3

    Enum.zip(program.statements, tests)
    |> Enum.each(fn {statement, expected} ->
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

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    assert "#{program}" == "let myVar = anotherVar;"
  end

  @tag disabled: true
  test "identifier expression" do
    input = "foobar;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    expression = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = expression

    assert %Parser.Identifier{token: %Token{type: :ident, literal: "foobar"}, value: "foobar"} =
             expression.expression
  end

  @tag disabled: true
  test "integer expression" do
    input = "5;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.IntegerLiteral{token: %Token{type: :int, literal: "5"}, value: 5} =
             statement.expression
  end

  @tag disabled: true
  test "string expression" do
    input = "\"hello\";"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.StringLiteral{token: %Token{type: :string, literal: "hello"}, value: "hello"} =
             statement.expression
  end

  @tag disabled: true
  test "prefix bang" do
    input = "!5;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement
    assert %Parser.PrefixExpression{} = statement.expression

    assert %Parser.PrefixExpression{
             token: %Token{type: :bang},
             operator: "!",
             right: %Parser.IntegerLiteral{}
           } = statement.expression
  end

  @tag disabled: true
  test "prefix minus" do
    input = "-5;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.PrefixExpression{
             token: %Token{type: :minus},
             operator: "-",
             right: %Parser.IntegerLiteral{}
           } = statement.expression
  end

  @tag disabled: true
  test "infix plus" do
    input = "5 + 5;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert %Parser.InfixExpression{
             token: %Token{type: :plus},
             operator: "+",
             left: %Parser.IntegerLiteral{},
             right: %Parser.IntegerLiteral{}
           } = statement.expression
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
      %{input: "!(true == true)", expected: "(!(true == true))"},
      %{input: "a * [1, 2, 3, 4][b * c] * d", expected: "((a * ([1, 2, 3, 4][(b * c)])) * d)"},
      %{input: "add(a * b[2], b[1], 2 * [1, 2][1])", expected: "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)

      assert "#{program}" == test.expected
    end)
  end

  @tag disabled: true
  test "true boolean expression" do
    input = "true;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

    {:ok, program} = Parser.Parser.parse_program(tokens)

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

  @tag disabled: true
  test "call expression" do
    # input = "add()"
    input = "add(1, 2 * 3, 4 + 5)"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %Parser.ExpressionStatement{} = statement

    assert length(statement.expression.arguments) == 3

    assert %Parser.CallExpression{
             function: %Identifier{value: "add"},
             arguments: [
               %IntegerLiteral{value: 1},
               %InfixExpression{
                 left: %IntegerLiteral{value: 2},
                 right: %IntegerLiteral{value: 3},
                 operator: "*"
               },
               %InfixExpression{
                 left: %IntegerLiteral{value: 4},
                 right: %IntegerLiteral{value: 5},
                 operator: "+"
               }
             ]
           } = statement.expression
  end

  @tag disabled: true
  test "operator precedence" do
    tests = [
      %{input: "add()", expected: "add()"},
      %{input: "a + add(b * c) + d", expected: "((a + add((b * c))) + d)"},
      %{
        input: "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
        expected: "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"
      },
      %{input: "add(a + b + c * d / f + g)", expected: "add((((a + b) + ((c * d) / f)) + g))"}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)

      assert "#{program}" == test.expected
    end)
  end

  @tag disabled: true
  test "arrays" do
    tests = [
      %{input: "[1, 2 * 2, 3 + 3]", expected: %ExpressionStatement{expression: %ArrayLiteral{
        elements: [
          %Parser.IntegerLiteral{token: %Token{literal: "1", type: :int}, value: 1},
          %Parser.InfixExpression{left: %Parser.IntegerLiteral{token: %Token{type: :int, literal: "2"}, value: 2}, operator: "*", right: %Parser.IntegerLiteral{token: %Token{type: :int, literal: "2"}, value: 2}, token: %Token{literal: "*", type: :asterix}},
          %Parser.InfixExpression{left: %Parser.IntegerLiteral{token: %Token{type: :int, literal: "3"}, value: 3}, operator: "+", right: %Parser.IntegerLiteral{token: %Token{type: :int, literal: "3"}, value: 3}, token: %Token{literal: "+", type: :plus}}
        ]
      }}},
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)

      statement = program.statements |> Enum.at(0)

      assert statement == test.expected
    end)
  end

  @tag disabled: true
  test "array index" do
    tests = [
      %{input: "foobar[1]", expected: %Parser.ExpressionStatement{expression: %Parser.IndexExpression{index: %Parser.IntegerLiteral{token: %Token{type: :int, literal: "1"}, value: 1}, left: %Parser.Identifier{token: %Token{type: :ident, literal: "foobar"}, value: "foobar"}, token: %Token{literal: "[", type: :lbracket}}, token: %Token{literal: nil, type: :expression}}},
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)

      statement = program.statements |> Enum.at(0)

      assert statement == test.expected
    end)
  end

  @tag disabled: true
  test "array index plus" do
    tests = [
      %{input: "foobar[1] + 1", expected: %Parser.ExpressionStatement{
              expression: %Parser.InfixExpression{
                left: %Parser.IndexExpression{index: %Parser.IntegerLiteral{value: 1, token: %Token{type: :int, literal: "1"}}, left: %Parser.Identifier{value: "foobar", token: %Token{type: :ident, literal: "foobar"}}, token: %Token{type: :lbracket, literal: "["}},
                operator: "+",
                right: %Parser.IntegerLiteral{token: %Token{type: :int, literal: "1"}, value: 1},
                token: %Token{literal: "+", type: :plus}
              },
              token: %Token{literal: nil, type: :expression}
            }},
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)

      statement = program.statements |> Enum.at(0)

      assert statement == test.expected
    end)
  end

  @tag disabled: true
  test "let and return statements" do
    tests = [
      %{
        input: "let x = 5;",
        expected: %Parser.LetStatement{
          name: %Identifier{value: "x"},
          value: %IntegerLiteral{value: 5}
        }
      },
      %{
        input: "let y = true;",
        expected: %Parser.LetStatement{
          name: %Identifier{value: "y"},
          value: %Boolean{value: true}
        }
      },
      %{
        input: "let foobar = y;",
        expected: %Parser.LetStatement{
          name: %Identifier{value: "foobar"},
          value: %Identifier{value: "y"}
        }
      },
      %{
        input: "return 5;",
        expected: %Parser.ReturnStatement{return_value: %IntegerLiteral{value: 5}}
      },
      %{
        input: "return true;",
        expected: %Parser.ReturnStatement{return_value: %Boolean{value: true}}
      },
      %{
        input: "return foobar;",
        expected: %Parser.ReturnStatement{return_value: %Identifier{value: "foobar"}}
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)

      _statement = program.statements |> Enum.at(0)
      assert _statement = test.expected
    end)
  end

  test "does it parse" do
    inputs = [
      "let add = fn(){ if(1 == 1) { x } else { y; let q = 1; } }",
      "let fibonacci = fn(x) { if (x == 0) { 0 } else { if (x == 1) { return 1; } else { fibonacci(x - 1) + fibonacci(x - 2); } } };",
      "if(true){}",
      "if(true){ let y = 7 } else { let x = 1 }",
      "if(true){ let a = fn(x,y,z){if(x>y>z){ print(x); return x; } else {print(y); print(z) return z;}}}"
    ]
    
    inputs |> Enum.each(fn input -> 
      tokens = Lexer.tokenize(input)
      {result, _} = Parser.Parser.parse_program(tokens)
      if result == :error do
        IO.puts(input)
      end
      assert result == :ok
    end)
  end

  test "fail parsing" do
    tests = [
      %{input: "let add = fn(){ if(1 == 1) { x  else { y; let q = 1; } }", errors: 4},
      %{input: "let fibonacci = fn(x) { else { if (x == 1) { return 1; } else { fibonacci(x - 1) + fibonacci(x - 2); }}};", errors: 1},
      %{input: "else", errors: 4},
      %{input: "if(true){ u = 7 } else { let x = 1 }", errors: 5},
      %{input: "if(true){ let a = fn(x,y.z){if(x>y>z){ print(x); return x; } else {print(y); print(z) return z;}}}",
    errors:  5}
    ]
    
    tests |> Enum.each(fn test -> 
      tokens = Lexer.tokenize(test.input)
      {result, _} = Parser.Parser.parse_program(tokens)
      assert result == :error
    end)
  end
  
end
