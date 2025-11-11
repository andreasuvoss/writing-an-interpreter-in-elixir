defmodule ParserTest do
  alias Lexer.Token
  use ExUnit.Case

  @tag disabled: true
  test "let statements" do
    input = """
    let x = 5;
    let y = 10;
    let foobar = 838383;
    """

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

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

    {:ok, program} = Parser.parse_program(tokens)

    tests = [
      "5",
      "10",
      "993322"
    ]

    assert length(program.statements) == 3

    Enum.zip(program.statements, tests)
    |> Enum.each(fn {statement, _} ->
      assert statement |> AST.Statement.token_literal() == "return"
      assert statement.token.type == :return
    end)
  end

  @tag disabled: true
  test "stringify program" do
    program = %AST.Program{
      statements: [
        %AST.LetStatement{
          token: %Token{type: :let, literal: "let"},
          name: %AST.Identifier{
            token: %Token{type: :ident, literal: "myVar"},
            value: "myVar"
          },
          value: %AST.Identifier{
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

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    expression = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = expression

    assert %AST.Identifier{token: %Token{type: :ident, literal: "foobar"}, value: "foobar"} =
             expression.expression
  end

  @tag disabled: true
  test "integer expression" do
    input = "5;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert %AST.IntegerLiteral{token: %Token{type: :int, literal: "5"}, value: 5} =
             statement.expression
  end

  @tag disabled: true
  test "string expression" do
    input = "\"hello\";"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert %AST.StringLiteral{token: %Token{type: :string, literal: "hello"}, value: "hello"} =
             statement.expression
  end

  @tag disabled: true
  test "prefix bang" do
    input = "!5;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement
    assert %AST.PrefixExpression{} = statement.expression

    assert %AST.PrefixExpression{
             token: %Token{type: :bang},
             operator: "!",
             right: %AST.IntegerLiteral{}
           } = statement.expression
  end

  @tag disabled: true
  test "prefix minus" do
    input = "-5;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert %AST.PrefixExpression{
             token: %Token{type: :minus},
             operator: "-",
             right: %AST.IntegerLiteral{}
           } = statement.expression
  end

  @tag disabled: true
  test "infix plus" do
    input = "5 + 5;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert %AST.InfixExpression{
             token: %Token{type: :plus},
             operator: "+",
             left: %AST.IntegerLiteral{},
             right: %AST.IntegerLiteral{}
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
      %{
        input: "add(a * b[2], b[1], 2 * [1, 2][1])",
        expected: "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.parse_program(tokens)

      assert "#{program}" == test.expected
    end)
  end

  @tag disabled: true
  test "true boolean expression" do
    input = "true;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert %AST.Boolean{token: %Token{type: true, literal: "true"}, value: true} =
             statement.expression
  end

  @tag disabled: true
  test "false boolean expression" do
    input = "false;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert %AST.Boolean{token: %Token{type: false, literal: "false"}, value: false} =
             statement.expression
  end

  @tag disabled: true
  test "let statement true boolean expression" do
    input = "let foobar = true;"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.LetStatement{} = statement

    assert %AST.Boolean{token: %Token{type: true, literal: "true"}, value: true} =
             statement.value
  end

  @tag disabled: true
  test "if expression" do
    input = "if (x < y) { x }"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert %AST.IfExpression{
             consequence: %AST.BlockStatement{
               statements: [%AST.ExpressionStatement{expression: %AST.Identifier{value: "x"}}]
             },
             alternative: nil
           } = statement.expression
  end

  @tag disabled: true
  test "if else expression" do
    input = "if (x < y) { x } else { y }"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert %AST.IfExpression{
             consequence: %AST.BlockStatement{
               statements: [%AST.ExpressionStatement{expression: %AST.Identifier{value: "x"}}]
             },
             alternative: %AST.BlockStatement{
               statements: [%AST.ExpressionStatement{expression: %AST.Identifier{value: "y"}}]
             }
           } = statement.expression
  end

  @tag disabled: true
  test "function literal" do
    input = "fn(x, y) { x + y }"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert length(statement.expression.parameters) == 2
    assert length(statement.expression.body.statements) == 1

    assert %AST.FunctionLiteral{
             body: %AST.BlockStatement{
               statements: [
                 %AST.ExpressionStatement{
                   expression: %AST.InfixExpression{
                     left: %AST.Identifier{value: "x"},
                     right: %AST.Identifier{value: "y"},
                     operator: "+"
                   }
                 }
               ]
             },
             parameters: [%AST.Identifier{value: "x"}, %AST.Identifier{value: "y"}]
           } = statement.expression
  end

  @tag disabled: true
  test "function literal single parameter" do
    input = "fn(x) { x }"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert length(statement.expression.parameters) == 1
    assert length(statement.expression.body.statements) == 1

    assert %AST.FunctionLiteral{
             body: %AST.BlockStatement{
               statements: [
                 %AST.ExpressionStatement{
                   expression: %AST.Identifier{value: "x"}
                 }
               ]
             },
             parameters: [%AST.Identifier{value: "x"}]
           } = statement.expression
  end

  @tag disabled: true
  test "function literal no parameters" do
    input = "fn() { x + y }"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert length(statement.expression.parameters) == 0
    assert length(statement.expression.body.statements) == 1

    assert %AST.FunctionLiteral{
             body: %AST.BlockStatement{
               statements: [
                 %AST.ExpressionStatement{
                   expression: %AST.InfixExpression{
                     left: %AST.Identifier{value: "x"},
                     right: %AST.Identifier{value: "y"},
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

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert length(statement.expression.parameters) == 0
    assert length(statement.expression.body.statements) == 0

    assert %AST.FunctionLiteral{
             body: %AST.BlockStatement{
               statements: []
             },
             parameters: []
           } = statement.expression
  end

  @tag disabled: true
  test "call expression" do
    input = "add(1, 2 * 3, 4 + 5)"

    tokens = Lexer.tokenize(input)

    {:ok, program} = Parser.parse_program(tokens)

    assert length(program.statements) == 1

    statement = program.statements |> Enum.at(0)
    assert %AST.ExpressionStatement{} = statement

    assert length(statement.expression.arguments) == 3

    assert %AST.CallExpression{
             function: %AST.Identifier{value: "add"},
             arguments: [
               %AST.IntegerLiteral{value: 1},
               %AST.InfixExpression{
                 left: %AST.IntegerLiteral{value: 2},
                 right: %AST.IntegerLiteral{value: 3},
                 operator: "*"
               },
               %AST.InfixExpression{
                 left: %AST.IntegerLiteral{value: 4},
                 right: %AST.IntegerLiteral{value: 5},
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
      {:ok, program} = Parser.parse_program(tokens)

      assert "#{program}" == test.expected
    end)
  end

  @tag disabled: true
  test "hashes" do
    tests = [
      %{
        input: "{\"one\": 1, \"two\": 2, \"three\": 3}",
        expected: %AST.ExpressionStatement{
          expression: %AST.HashLiteral{
            pairs: %{
              %AST.StringLiteral{token: %Token{literal: "one", type: :string}, value: "one"} =>
                %AST.IntegerLiteral{token: %Token{literal: "1", type: :int}, value: 1},
              %AST.StringLiteral{token: %Token{literal: "two", type: :string}, value: "two"} =>
                %AST.IntegerLiteral{token: %Token{literal: "2", type: :int}, value: 2},
              %AST.StringLiteral{
                token: %Token{literal: "three", type: :string},
                value: "three"
              } => %AST.IntegerLiteral{token: %Token{literal: "3", type: :int}, value: 3}
            }
          }
        }
      },
      %{
        input: "{1: \"one\", true: 2, 4*2: 3+8}",
        expected: %AST.ExpressionStatement{
          expression: %AST.HashLiteral{
            pairs: %{
              %AST.IntegerLiteral{token: %Token{literal: "1", type: :int}, value: 1} =>
                %AST.StringLiteral{token: %Token{literal: "one", type: :string}, value: "one"},
              %AST.Boolean{token: %Token{literal: "true", type: true}, value: true} =>
                %AST.IntegerLiteral{token: %Token{literal: "2", type: :int}, value: 2},
              %AST.InfixExpression{
                token: %Token{literal: "*", type: :asterix},
                left: %AST.IntegerLiteral{token: %Token{literal: "4", type: :int}, value: 4},
                right: %AST.IntegerLiteral{token: %Token{literal: "2", type: :int}, value: 2},
                operator: "*"
              } => %AST.InfixExpression{
                token: %Token{literal: "+", type: :plus},
                left: %AST.IntegerLiteral{token: %Token{literal: "3", type: :int}, value: 3},
                right: %AST.IntegerLiteral{token: %Token{literal: "8", type: :int}, value: 8},
                operator: "+"
              }
            }
          }
        }
      },
      %{
        input: "{}",
        expected: %AST.ExpressionStatement{
          expression: %AST.HashLiteral{
            pairs: %{}
          }
        }
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.parse_program(tokens)

      statement = program.statements |> Enum.at(0)

      assert statement == test.expected
    end)
  end

  @tag disabled: true
  test "arrays" do
    tests = [
      %{
        input: "[1, 2 * 2, 3 + 3]",
        expected: %AST.ExpressionStatement{
          expression: %AST.ArrayLiteral{
            elements: [
              %AST.IntegerLiteral{token: %Token{literal: "1", type: :int}, value: 1},
              %AST.InfixExpression{
                left: %AST.IntegerLiteral{token: %Token{type: :int, literal: "2"}, value: 2},
                operator: "*",
                right: %AST.IntegerLiteral{token: %Token{type: :int, literal: "2"}, value: 2},
                token: %Token{literal: "*", type: :asterix}
              },
              %AST.InfixExpression{
                left: %AST.IntegerLiteral{token: %Token{type: :int, literal: "3"}, value: 3},
                operator: "+",
                right: %AST.IntegerLiteral{token: %Token{type: :int, literal: "3"}, value: 3},
                token: %Token{literal: "+", type: :plus}
              }
            ]
          }
        }
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.parse_program(tokens)

      statement = program.statements |> Enum.at(0)

      assert statement == test.expected
    end)
  end

  @tag disabled: true
  test "array index" do
    tests = [
      %{
        input: "foobar[1]",
        expected: %AST.ExpressionStatement{
          expression: %AST.IndexExpression{
            index: %AST.IntegerLiteral{token: %Token{type: :int, literal: "1"}, value: 1},
            left: %AST.Identifier{
              token: %Token{type: :ident, literal: "foobar"},
              value: "foobar"
            },
            token: %Token{literal: "[", type: :lbracket}
          },
          token: %Token{literal: nil, type: :expression}
        }
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.parse_program(tokens)

      statement = program.statements |> Enum.at(0)

      assert statement == test.expected
    end)
  end

  @tag disabled: true
  test "hash index" do
    tests = [
      %{
        input: "{123: true}[0]",
        expected: %AST.ExpressionStatement{
          expression: %AST.IndexExpression{
            index: %AST.IntegerLiteral{token: %Token{type: :int, literal: "0"}, value: 0},
            left: %AST.HashLiteral{
              token: %Token{type: :rbracket, literal: "{"},
              pairs: %{
                %AST.IntegerLiteral{value: 123, token: %Token{type: :int, literal: "123"}} =>
                  %AST.Boolean{value: true}
              }
            },
            token: %Token{literal: "[", type: :lbracket}
          },
          token: %Token{literal: nil, type: :expression}
        }
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.parse_program(tokens)

      statement = program.statements |> Enum.at(0)

      assert statement == test.expected
    end)
  end

  @tag disabled: true
  test "array index plus" do
    tests = [
      %{
        input: "foobar[1] + 1",
        expected: %AST.ExpressionStatement{
          expression: %AST.InfixExpression{
            left: %AST.IndexExpression{
              index: %AST.IntegerLiteral{value: 1, token: %Token{type: :int, literal: "1"}},
              left: %AST.Identifier{
                value: "foobar",
                token: %Token{type: :ident, literal: "foobar"}
              },
              token: %Token{type: :lbracket, literal: "["}
            },
            operator: "+",
            right: %AST.IntegerLiteral{token: %Token{type: :int, literal: "1"}, value: 1},
            token: %Token{literal: "+", type: :plus}
          },
          token: %Token{literal: nil, type: :expression}
        }
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.parse_program(tokens)

      statement = program.statements |> Enum.at(0)

      assert statement == test.expected
    end)
  end

  @tag disabled: true
  test "let and return statements" do
    tests = [
      %{
        input: "let x = 5;",
        expected: %AST.LetStatement{
          name: %AST.Identifier{value: "x"},
          value: %AST.IntegerLiteral{value: 5}
        }
      },
      %{
        input: "let y = true;",
        expected: %AST.LetStatement{
          name: %AST.Identifier{value: "y"},
          value: %AST.Boolean{value: true}
        }
      },
      %{
        input: "let foobar = y;",
        expected: %AST.LetStatement{
          name: %AST.Identifier{value: "foobar"},
          value: %AST.Identifier{value: "y"}
        }
      },
      %{
        input: "return 5;",
        expected: %AST.ReturnStatement{return_value: %AST.IntegerLiteral{value: 5}}
      },
      %{
        input: "return true;",
        expected: %AST.ReturnStatement{return_value: %AST.Boolean{value: true}}
      },
      %{
        input: "return foobar;",
        expected: %AST.ReturnStatement{return_value: %AST.Identifier{value: "foobar"}}
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.tokenize(test.input)
      {:ok, program} = Parser.parse_program(tokens)

      _statement = program.statements |> Enum.at(0)
      assert _statement = test.expected
    end)
  end

  @tag disabled: true
  test "modify" do
    one = fn -> %AST.ExpressionStatement{expression: %AST.IntegerLiteral{value: 1}} end
    two = fn -> %AST.ExpressionStatement{expression: %AST.IntegerLiteral{value: 2}} end

    turn_one_into_two = fn %AST.IntegerLiteral{} = node ->
      if node.value != 1 do
        {:ok, node}
      else
        {:ok, %{node | value: 2}}
      end
    end

    tests = [
      %{
        input: one.(),
        expected: two.()
      },
      %{
        input: %AST.Program{
          statements: [
            %AST.ExpressionStatement{expression: one.()}
          ]
        },
        expected: %AST.Program{
          statements: [
            %AST.ExpressionStatement{expression: two.()}
          ]
        }
      },
      %{
        input: %AST.InfixExpression{left: one.(), operator: "+", right: two.()},
        expected: %AST.InfixExpression{left: two.(), operator: "+", right: two.()}
      },
      %{
        input: %AST.InfixExpression{left: two.(), operator: "+", right: one.()},
        expected: %AST.InfixExpression{left: two.(), operator: "+", right: two.()}
      },
      %{
        input: %AST.PrefixExpression{operator: "-", right: one.()},
        expected: %AST.PrefixExpression{operator: "-", right: two.()}
      },
      %{
        input: %AST.IndexExpression{left: one.(), index: one.()},
        expected: %AST.IndexExpression{left: two.(), index: two.()}
      },
      %{
        input: %AST.IfExpression{
          condition: one.(),
          consequence: %AST.BlockStatement{
            statements: [
              %AST.ExpressionStatement{expression: one.()}
            ]
          },
          alternative: %AST.BlockStatement{
            statements: [
              %AST.ExpressionStatement{expression: one.()}
            ]
          }
        },
        expected: %AST.IfExpression{
          condition: two.(),
          consequence: %AST.BlockStatement{
            statements: [
              %AST.ExpressionStatement{expression: two.()}
            ]
          },
          alternative: %AST.BlockStatement{
            statements: [
              %AST.ExpressionStatement{expression: two.()}
            ]
          }
        }
      },
      %{
        input: %AST.ReturnStatement{return_value: one.()},
        expected: %AST.ReturnStatement{return_value: two.()}
      },
      %{
        input: %AST.LetStatement{value: one.()},
        expected: %AST.LetStatement{value: two.()}
      },
      %{
        input: %AST.FunctionLiteral{
          parameters: [],
          body: %AST.BlockStatement{
            statements: [
              %AST.ExpressionStatement{expression: one.()}
            ]
          }
        },
        expected: %AST.FunctionLiteral{
          parameters: [],
          body: %AST.BlockStatement{
            statements: [
              %AST.ExpressionStatement{expression: two.()}
            ]
          }
        }
      },
      %{
        input: %AST.ArrayLiteral{elements: [one.()]},
        expected: %AST.ArrayLiteral{elements: [two.()]}
      },
      %{
        input: %AST.HashLiteral{
          pairs: %{
            one.() => one.(),
            one.() => one.()
          }
        },
        expected: %AST.HashLiteral{
          pairs: %{
            two.() => two.(),
            two.() => two.()
          }
        }
      }
    ]

    tests
    |> Enum.each(fn test ->
      {:ok, modified} = Parser.Modify.modify(test.input, turn_one_into_two)
      assert modified == test.expected
    end)
  end

  @tag disabled: true
  test "macro literal" do
    input = "macro(x , y) { x + y; }"
    tokens = Lexer.tokenize(input)
    {:ok, program} = Parser.parse_program(tokens)

    statement = Enum.at(program.statements, 0)

    assert length(program.statements) == 1

    assert statement == %AST.ExpressionStatement{
             expression: %AST.MacroLiteral{
               body: %AST.BlockStatement{
                 token: %Token{type: :lbrace, literal: "{"},
                 statements: [
                   %AST.ExpressionStatement{
                     token: %Token{type: :expression, literal: nil},
                     expression: %AST.InfixExpression{
                       token: %Token{type: :plus, literal: "+"},
                       left: %AST.Identifier{
                         token: %Token{type: :ident, literal: "x"},
                         value: "x"
                       },
                       operator: "+",
                       right: %AST.Identifier{
                         token: %Token{type: :ident, literal: "y"},
                         value: "y"
                       }
                     }
                   }
                 ]
               },
               token: %Token{type: :macro, literal: "macro"},
               parameters: [
                 %AST.Identifier{token: %Token{type: :ident, literal: "x"}, value: "x"},
                 %AST.Identifier{token: %Token{type: :ident, literal: "y"}, value: "y"}
               ]
             },
             token: %Token{literal: nil, type: :expression}
           }
  end

  test "does it parse" do
    inputs = [
      "let add = fn(){ if(1 == 1) { x } else { y; let q = 1; } }",
      "let fibonacci = fn(x) { if (x == 0) { 0 } else { if (x == 1) { return 1; } else { fibonacci(x - 1) + fibonacci(x - 2); } } };",
      "if(true){}",
      "if(true){ let y = 7 } else { let x = 1 }",
      "if(true){ let a = fn(x,y,z){if(x>y>z){ print(x); return x; } else {print(y); print(z) return z;}}}"
    ]

    inputs
    |> Enum.each(fn input ->
      tokens = Lexer.tokenize(input)
      {result, _} = Parser.parse_program(tokens)

      if result == :error do
        IO.puts(input)
      end

      assert result == :ok
    end)
  end

  test "fail parsing" do
    tests = [
      %{input: "let add = fn(){ if(1 == 1) { x  else { y; let q = 1; } }"},
      %{input: "let fibonacci = fn(x) { else { if (x == 1) { return 1; } else { fibonacci(x - 1) + fibonacci(x - 2); }}};"},
      %{input: "else"},
      %{input: "if(true){ u = 7 } else { let x = 1 }"},
      %{input: "if(true){ let a = fn(x,y.z){if(x>y>z){ print(x); return x; } else {print(y); print(z) return z;}}}"}
    ]
    
    tests |> Enum.each(fn test -> 
      tokens = Lexer.tokenize(test.input)
      {result, _} = Parser.parse_program(tokens)
      assert result == :error
    end)
  end
end
