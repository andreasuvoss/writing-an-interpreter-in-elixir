defmodule EvaluatorTest do
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
      %{input: "(5 + 10 * 2 + 15 / 3) * 2 + -10", expected: 50},
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated} = Evaluator.Evaluator.eval(program)

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
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated} = Evaluator.Evaluator.eval(program)
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
      %{input: "!!5", expected: true},
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated} = Evaluator.Evaluator.eval(program)
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
      %{input: "if (1 < 2) { 10 } else { 20 }", expected: 10},
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated} = Evaluator.Evaluator.eval(program)
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
      %{input: "if (10 > 1) { if(10 > 1) { 10; 65; return 19; } 9 7 7; return 1 }", expected: 19},
    ]

    tests
    |> Enum.each(fn test ->
      tokens = Lexer.Lexer.tokenize(test.input)
      {:ok, program} = Parser.Parser.parse_program(tokens)
      {:ok, evaluated} = Evaluator.Evaluator.eval(program)
      assert create_integer(test.expected) == evaluated
    end)
  end

  defp create_boolean(value) do
    %Evaluator.Boolean{value: value}
  end

  defp create_integer(nil) do
    %Evaluator.Null{}
  end
  defp create_integer(value) do
    %Evaluator.Integer{value: value}
  end
end
