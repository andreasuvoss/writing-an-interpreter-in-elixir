defmodule EvaluatorTest do
  # alias Evaluator.Integer
  # alias Evaluator.Boolean
  # alias Evaluator.Integer
  use ExUnit.Case

  @tag disabled: true
  test "evaluate interger expression" do
    tests = [
      %{input: "5", expected: 5},
      %{input: "10", expected: 10},
      %{input: "-5", expected: -5},
      %{input: "-10", expected: -10},
      %{input: "5 + 5 + 5 + 5 - 10", expected: 10},
      %{input: "2 * 2 * 2 * 2 * 2", expected: 32},
      %{input: "-50 + 100 + -50", expected: 0},
      %{input: "5 * 2 + 10", expected: 20},
      %{input: "5 + 2 * 10", expected: 25},
      %{input: "20 + 2 * -10", expected: 0},
      %{input: "50 / 2 * 2 + 10", expected: 60},
      %{input: "2 * (5 + 10)", expected: 30},
      %{input: "3 * 3 * 3 + 10", expected: 37},
      %{input: "3 * (3 * 3) + 10", expected: 37},
      %{input: "(5 + 10 * 2 + 15 / 3) * 2 + -10", expected: 50}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})

      assert create_integer(test.expected) == evaluated
    end)
  end

  @tag disabled: true
  test "evaluate boolean expression" do
    tests = [
      %{input: "true", expected: true},
      %{input: "false", expected: false},
      %{input: "1 < 2", expected: true},
      %{input: "1 > 2", expected: false},
      %{input: "1 < 1", expected: false},
      %{input: "1 > 1", expected: false},
      %{input: "1 == 1", expected: true},
      %{input: "1 != 1", expected: false},
      %{input: "1 == 2", expected: false},
      %{input: "1 != 2", expected: true},
      %{input: "true == true", expected: true},
      %{input: "false == false", expected: true},
      %{input: "true == false", expected: false},
      %{input: "true != false", expected: true},
      %{input: "false != true", expected: true},
      %{input: "(1 < 2) == true", expected: true},
      %{input: "(1 < 2) == false", expected: false},
      %{input: "(1 > 2) == true", expected: false},
      %{input: "(1 > 2) == false", expected: true},
      %{input: "\"test\" == \"test\"", expected: true},
      %{input: "\"test\" == \"test1\"", expected: false},
      %{input: "\"test\" != \"test\"", expected: false},
      %{input: "\"test\" != \"test1\"", expected: true}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert create_boolean(test.expected) == evaluated
    end)
  end

  @tag disabled: true
  test "evaluate bang prefix" do
    tests = [
      %{input: "!true", expected: false},
      %{input: "!false", expected: true},
      %{input: "!5", expected: false},
      %{input: "!!true", expected: true},
      %{input: "!!false", expected: false},
      %{input: "!!5", expected: true}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert create_boolean(test.expected) == evaluated
    end)
  end

  @tag disabled: true
  test "evaluate if else expressions" do
    tests = [
      %{input: "if(true){ 10 }", expected: 10},
      %{input: "if(false) { 10 }", expected: nil},
      %{input: "if (1) { 10 }", expected: 10},
      %{input: "if (1 < 2) { 10 }", expected: 10},
      %{input: "if (1 > 2) { 10 }", expected: nil},
      %{input: "if (1 > 2) { 10 } else { 20 }", expected: 20},
      %{input: "if (1 < 2) { 10 } else { 20 }", expected: 10}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert create_integer(test.expected) == evaluated
    end)
  end

  @tag disabled: true
  test "evaluate return statements" do
    tests = [
      %{input: "return 10;", expected: 10},
      %{input: "return 10; 9;", expected: 10},
      %{input: "return 2 * 5; 9;", expected: 10},
      %{input: "9; return 2 * 5; 9", expected: 10},
      %{input: "if(10 > 1) { if(10 > 1) { return 10; } return 1; }", expected: 10},
      %{input: "if (10 > 1) { if(10 > 1) { 10; 65; return 19; } 9 7 7; return 1 }", expected: 19}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert create_integer(test.expected) == evaluated
    end)
  end

  @tag disabled: true
  test "error handling" do
    tests = [
      %{input: "5 + true;", expected: "ERROR: type mismatch: INTEGER + BOOLEAN"},
      %{input: "5 + true; 5;", expected: "ERROR: type mismatch: INTEGER + BOOLEAN"},
      %{input: "-true", expected: "ERROR: unknown operator: -BOOLEAN"},
      %{input: "true + false", expected: "ERROR: unknown operator: BOOLEAN + BOOLEAN"},
      %{input: "5; true + false; 5", expected: "ERROR: unknown operator: BOOLEAN + BOOLEAN"},
      %{input: "{false:5}[fn(x){ x }]", expected: "ERROR: unsupported index type: FUNCTION"},
      %{
        input: "if(10 > 1){ true + false; }",
        expected: "ERROR: unknown operator: BOOLEAN + BOOLEAN"
      },
      %{
        input: "if(10 > 1){if(10 > 1){ true + false; } return 1; }",
        expected: "ERROR: unknown operator: BOOLEAN + BOOLEAN"
      },
      %{
        input: "if(10 > 1){if(10 > 1){ 1 + false; } return 1; }",
        expected: "ERROR: type mismatch: INTEGER + BOOLEAN"
      },
      %{input: "foobar", expected: "ERROR: identifier not found: foobar"}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      # {:error, evaluated} = Evaluator.eval(program)
      {status, error} = Evaluator.eval(program, %Evaluator.Environment{})
      assert status == :error
      assert error.message == test.expected
    end)
  end

  @tag disabled: true
  test "let statement" do
    tests = [
      # %{input: "let a = 5; a;", expected: 0},
      %{input: "let a = 5; a;", expected: 5},
      %{input: "let a = 5 * 5; a;", expected: 25},
      %{input: "let a = 5; let b = a; b;", expected: 5},
      %{input: "let a = 5; let b = a; let c = a + b + 5; c;", expected: 15}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert create_integer(test.expected) == evaluated
    end)
  end

  @tag disabled: true
  test "functions" do
    tests = [
      # %{input: "let a = 5; a;", expected: 0},
      %{input: "fn(x) { x + 2 };", expected: 5}
      # %{input: "let a = 5 * 5; a;", expected: 25},
      # %{input: "let a = 5; let b = a; b;", expected: 5},
      # %{input: "let a = 5; let b = a; let c = a + b + 5; c;", expected: 15},
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert %Evaluator.Function{} = evaluated
    end)
  end

  @tag disabled: true
  test "function application" do
    tests = [
      %{input: "let identity = fn(x) { x; }; identity(5);", expected: 5},
      %{input: "let identity = fn(x) { return x; }; identity(5);", expected: 5},
      %{input: "let double = fn(x) { x * 2; }; double(5);", expected: 10},
      %{input: "let add = fn(x, y) { x + y; }; add(5, 5);", expected: 10},
      %{input: "let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", expected: 20},
      %{input: "fn(x) {x;}(5)", expected: 5}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert create_integer(test.expected) == evaluated
    end)
  end

  @tag disabled: true
  test "closures" do
    input = """
    let newAdder = fn(x) {
      fn(y) { x + y }
    };

    let addTwo = newAdder(2);
    let addThree = newAdder(3);
    addTwo(2);
    """

    tokens = Lexer.Lexer.tokenize(input)
    {:ok, program} = Parser.Parser.parse_program(tokens)
    {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})

    assert create_integer(4) == evaluated
  end

  @tag disabled: true
  test "recursion" do
    input = """
    let counter = fn(x, y) {
      if (x > y) {
        return true; 
      }
      else
      {
        counter(x+1, y)
      }
    };

    counter(0, 100)
    """

    tokens = Lexer.Lexer.tokenize(input)
    {:ok, program} = Parser.Parser.parse_program(tokens)
    {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})

    assert create_boolean(true) == evaluated
  end

  @tag disabled: true
  test "hashes" do
    input = """
    let two = "two";
    {
      "one": 10 - 9,
      two: 1 + 1,
      "thr" + "ee": 6 / 2,
      4: 4,
      true: 5,
      false: 6
    }
    """

    tokens = Lexer.Lexer.tokenize(input)
    {:ok, program} = Parser.Parser.parse_program(tokens)
    {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})

    assert %Evaluator.Hash{
             pairs: %{
               %Evaluator.String{value: "two"} => %Evaluator.Integer{value: 2},
               %Evaluator.Integer{value: 4} => %Evaluator.Integer{value: 4},
               %Evaluator.Boolean{value: false} => %Evaluator.Integer{value: 6},
               %Evaluator.Boolean{value: true} => %Evaluator.Integer{value: 5},
               %Evaluator.String{value: "one"} => %Evaluator.Integer{value: 1},
               %Evaluator.String{value: "three"} => %Evaluator.Integer{value: 3}
             }
           } == evaluated
  end

  @tag disabled: true
  test "strings" do
    input = """
    let text = "some text";
    """

    tokens = Lexer.Lexer.tokenize(input)
    {:ok, program} = Parser.Parser.parse_program(tokens)
    {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})

    assert create_string("some text") == evaluated
  end

  @tag disabled: true
  test "string concat" do
    input = """
    "Hello" + " " + "World!"
    """

    tokens = Lexer.Lexer.tokenize(input)
    {:ok, program} = Parser.Parser.parse_program(tokens)
    {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})

    assert create_string("Hello World!") == evaluated
  end

  @tag disabled: true
  test "array literals" do
    input = """
    let myArray = [1,2,2 * 2,3 + 3]
    """

    tokens = Lexer.Lexer.tokenize(input)
    {:ok, program} = Parser.Parser.parse_program(tokens)
    {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})

    assert Enum.at(evaluated.elements, 0) == create_integer(1)
    assert Enum.at(evaluated.elements, 1) == create_integer(2)
    assert Enum.at(evaluated.elements, 2) == create_integer(4)
    assert Enum.at(evaluated.elements, 3) == create_integer(6)
  end

  @tag disabled: true
  test "array indicies" do
    tests = [
      %{input: "[1, 2, 3][0]", expected: 1},
      %{input: "[1, 2, 3][1]", expected: 2},
      %{input: "[1, 2, 3][2]", expected: 3},
      %{input: "let i = 0; [1][i]", expected: 1},
      %{input: "[1, 2, 3][1 + 1]", expected: 3},
      %{input: "let myArray = [1, 2, 3]; myArray[2]", expected: 3},
      %{input: "let myArray = [1, 2, 3]; myArray[0] + 1", expected: 2},
      %{input: "let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2]", expected: 6},
      %{input: "let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]", expected: 2},
      %{input: "[1, 2, 3][3]", expected: nil},
      %{input: "[1, 2, 3][-1]", expected: nil}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert create_integer(test.expected) == evaluated
    end)
  end

  @tag disabled: true
  test "hash indicies" do
    tests = [
      %{input: "{88: 1}[88]", expected: create_integer(1)},
      %{input: "{\"foo\": 5}[\"foo\"]", expected: create_integer(5)},
      %{input: "{\"foo\": 5}[\"bar\"]", expected: create_nil()},
      %{input: "let key = \"foo\"; {\"foo\": 5}[key]", expected: create_integer(5)},
      %{input: "{}[\"foo\"]", expected: create_nil()},
      %{input: "{5:5}[5]", expected: create_integer(5)},
      %{input: "{true:5}[true]", expected: create_integer(5)},
      %{input: "{false:5}[false]", expected: create_integer(5)}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert test.expected == evaluated
    end)
  end

  @tag disabled: true
  test "quote" do
    tests = [
      %{input: "quote(5)", expected: "5"},
      %{input: "quote(5 + 8)", expected: "(5 + 8)"},
      %{input: "quote(foobar)", expected: "foobar"},
      %{input: "quote(foobar + barfoo)", expected: "(foobar + barfoo)"}
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert test.expected == "#{evaluated.node}"
    end)
  end

  @tag disabled: true
  test "unquote" do
    tests = [
      %{input: "quote(unquote(4))", expected: "4"},
      %{input: "quote(unquote(4 + 4))", expected: "8"},
      %{input: "quote(8 + unquote(4 + 4))", expected: "(8 + 8)"},
      %{input: "quote(unquote(4 + 4) + 8)", expected: "(8 + 8)"},
      %{input: "let foobar = 8; quote(foobar)", expected: "foobar"},
      %{input: "let foobar = 8; quote(unquote(foobar))", expected: "8"},
      %{input: "quote(unquote(true))", expected: "true"},
      %{input: "quote(unquote(true == false))", expected: "false"},
      %{input: "quote(unquote(quote(4 + 4)))", expected: "(4 + 4)"},
      %{
        input:
          "let quotedInfixExpression = quote(4 + 4); quote(unquote(4 + 4) + unquote(quotedInfixExpression))",
        expected: "(8 + (4 + 4))"
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert test.expected == "#{evaluated.node}"
    end)
  end

  @tag disabled: true
  test "define macros" do
    input = """
    let number = 1; 
    let function = fn(x, y) { x + y }; 
    let mymacro = macro(x, y) { x + y; };
    """

    tokens = Lexer.Lexer.tokenize(input)
    {:ok, program} = Parser.Parser.parse_program(tokens)
    {:ok, program, env} = Evaluator.define_macros(program, %Evaluator.Environment{})

    assert length(program.statements) == 2
    assert map_size(env.store) == 1

    assert Evaluator.Environment.get(env, "mymacro") ==
             {:ok,
              %Evaluator.Macro{
                body: %Parser.BlockStatement{
                  token: %Lexer.Token{type: :lbrace, literal: "{"},
                  statements: [
                    %Parser.ExpressionStatement{
                      token: %Lexer.Token{type: :expression, literal: nil},
                      expression: %Parser.InfixExpression{
                        token: %Lexer.Token{type: :plus, literal: "+"},
                        left: %Parser.Identifier{
                          token: %Lexer.Token{type: :ident, literal: "x"},
                          value: "x"
                        },
                        operator: "+",
                        right: %Parser.Identifier{
                          token: %Lexer.Token{type: :ident, literal: "y"},
                          value: "y"
                        }
                      }
                    }
                  ]
                },
                env: %Evaluator.Environment{store: %{}, outer: nil},
                parameters: [
                  %Parser.Identifier{token: %Lexer.Token{type: :ident, literal: "x"}, value: "x"},
                  %Parser.Identifier{token: %Lexer.Token{type: :ident, literal: "y"}, value: "y"}
                ]
              }}
  end

  @tag disabled: true
  test "macro expansion" do
    tests = [
      %{input: "let infix = macro() { quote(1+2) }; infix();", expected: "(1 + 2)"},
      %{input: "let rev = macro(a,b) { quote(unquote(b) - unquote(a));}; rev(2 + 2, 10 - 5)", expected: "(10 - 5) - (2 + 2)"},
      %{input: """
            let unless = macro(condition, consequence, alternative) {
                quote(if (!(unquote(condition))) {
                    unquote(consequence);
                } else {
                    unquote(alternative);
                });
            };

            unless(10 > 5, puts("not greater"), puts("greater"));
        """, expected: "if (!(10 > 5)) { puts(\"not greater\") } else { puts(\"greater\") }"},
    ]
    tests
    |> Enum.each(fn test ->
      expected = test_parse_program(test.expected)
      program = test_parse_program(test.input)
      {:ok, program, env} = Evaluator.define_macros(program, %Evaluator.Environment{})

      # IO.inspect(program)
      # IO.inspect(env)
      {:ok, expanded} = Evaluator.expand_macros(program, env)
      # IO.inspect(expanded)

      # IO.inspect(expanded)
      assert "#{expected}" == "#{expanded}"
    end)
  end

  @tag disabled: true
  test "builtin functions" do
    tests = [
      %{input: "len(\"\")", expected: create_integer(0)},
      %{input: "len(\"hello\")", expected: create_integer(5)},
      %{input: "len(\"four\")", expected: create_integer(4)},
      %{input: "len(\"hello world\")", expected: create_integer(11)},
      %{input: "len([1,2,3])", expected: create_integer(3)},
      %{input: "let x = [1,2]; len(x)", expected: create_integer(2)},
      %{input: "let x = [1,2]; first(x)", expected: create_integer(1)},
      %{input: "let x = [1,2]; last(x)", expected: create_integer(2)},
      %{input: "let x = [1,2]; rest(x)", expected: create_array([create_integer(2)])},
      %{
        input: "let x = [1,2,4]; rest(x)",
        expected: create_array([create_integer(2), create_integer(4)])
      },
      %{
        input: "let a = [1,2,3,4]; rest(rest(a))",
        expected: create_array([create_integer(3), create_integer(4)])
      },
      %{
        input: "let a = [1,2,3,4]; let b = push(a, 5); b",
        expected:
          create_array([
            create_integer(1),
            create_integer(2),
            create_integer(3),
            create_integer(4),
            create_integer(5)
          ])
      },
      %{
        input: "let a = [1,2,3,4]; let b = push(a, 5); a",
        expected:
          create_array([
            create_integer(1),
            create_integer(2),
            create_integer(3),
            create_integer(4)
          ])
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated, _} = Evaluator.eval(program, %Evaluator.Environment{})
      assert test.expected == evaluated
    end)
  end

  @tag disabled: true
  test "builtin errors" do
    tests = [
      %{
        input: "len(1)",
        expected: %Evaluator.Error{message: "ERROR: argument to `len` not supported, got INTEGER"}
      },
      %{
        input: "len(\"one\", \"two\")",
        expected: %Evaluator.Error{message: "ERROR: wrong number of arguments got 2 want 1"}
      }
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:error, evaluated} = Evaluator.eval(program, %Evaluator.Environment{})
      assert test.expected == evaluated
    end)
  end

  defp create_boolean(value) do
    %Evaluator.Boolean{value: value}
  end

  defp create_nil() do
    %Evaluator.Null{}
  end

  defp create_integer(nil) do
    %Evaluator.Null{}
  end

  defp create_integer(value) do
    %Evaluator.Integer{value: value}
  end

  defp create_string(value) do
    %Evaluator.String{value: value}
  end

  defp create_array(elements) do
    %Evaluator.Array{elements: elements}
  end

  defp test_parse_program(input) do
      tokens = Lexer.Lexer.tokenize(input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      program
  end
end
