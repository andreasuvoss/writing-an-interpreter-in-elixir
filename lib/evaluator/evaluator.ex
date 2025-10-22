defmodule Evaluator.Evaluator do
  # alias Parser.ReturnStatement
  # alias Evaluator.Boolean
  # alias Parser.Boolean
  alias Parser.ExpressionStatement
  # alias Parser.IfExpression
  alias Parser.BlockStatement
  alias Parser.IntegerLiteral
  alias Evaluator.Integer
  alias Parser.Program

  def eval(%Program{} = program) do
    case eval_program(program.statements) do
      {:ok, result} -> {:ok, result}
    end
  end

  def eval(%ExpressionStatement{} = expression_statement) do
    eval(expression_statement.expression)
  end

  def eval(%BlockStatement{statements: statements}) do
    eval_block_statements(statements)
  end

  def eval(%Parser.ReturnStatement{return_value: return_value}) do
    case eval(return_value) do
       {:ok, value} -> {:ok, %Evaluator.Return{value: value}}
    end
  end

  def eval(%Parser.IfExpression{} = expr) do
    {:ok, condition} = eval(expr.condition)

    case {is_truthy?(condition), expr.alternative} do
      {true, _} -> eval(expr.consequence)
      {false, nil} -> {:ok, %Evaluator.Null{}}
      {false, alternative} -> eval(alternative)
    end
  end

  def eval(%IntegerLiteral{} = integer) do
    {:ok, %Integer{value: integer.value}}
  end

  def eval(%Parser.Boolean{} = bool) do
    {:ok, %Evaluator.Boolean{value: bool.value}}
  end

  def eval(%Parser.PrefixExpression{} = expr) do
    case eval(expr.right) do
      {:ok, right} -> eval_prefix_expression(expr.operator, right)
    end
  end

  def eval(%Parser.InfixExpression{} = expr) do
    case eval(expr.left) do
      {:ok, left} ->
        case eval(expr.right) do
          {:ok, right} -> eval_infix_expression(expr.operator, left, right)
        end
    end
  end

  defp is_truthy?(value) do
    case value do
      %Evaluator.Null{} -> false
      %Evaluator.Boolean{value: true} -> true
      %Evaluator.Boolean{value: false} -> false
      _ -> true
    end
  end

  defp eval_infix_expression("+", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right) do
    {:ok, %Evaluator.Integer{value: left.value + right.value}}
  end

  defp eval_infix_expression("-", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right) do
    {:ok, %Evaluator.Integer{value: left.value - right.value}}
  end

  defp eval_infix_expression("*", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right) do
    {:ok, %Evaluator.Integer{value: left.value * right.value}}
  end

  defp eval_infix_expression("/", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right) do
    {:ok, %Evaluator.Integer{value: left.value / right.value}}
  end

  defp eval_infix_expression(">", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right) do
    {:ok, %Evaluator.Boolean{value: left.value > right.value}}
  end

  defp eval_infix_expression("<", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right) do
    {:ok, %Evaluator.Boolean{value: left.value < right.value}}
  end

  defp eval_infix_expression("==", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right) do
    {:ok, %Evaluator.Boolean{value: left.value == right.value}}
  end

  defp eval_infix_expression("!=", %Evaluator.Integer{} = left, %Evaluator.Integer{} = right) do
    {:ok, %Evaluator.Boolean{value: left.value != right.value}}
  end

  defp eval_infix_expression("==", %Evaluator.Boolean{} = left, %Evaluator.Boolean{} = right) do
    {:ok, %Evaluator.Boolean{value: left.value == right.value}}
  end

  defp eval_infix_expression("!=", %Evaluator.Boolean{} = left, %Evaluator.Boolean{} = right) do
    {:ok, %Evaluator.Boolean{value: left.value != right.value}}
  end

  defp eval_infix_expression(_, _, _) do
    {:ok, %Evaluator.Null{}}
  end

  defp eval_prefix_expression("!", right) do
    case right do
      %Evaluator.Boolean{value: true} -> {:ok, %Evaluator.Boolean{value: false}}
      %Evaluator.Boolean{value: false} -> {:ok, %Evaluator.Boolean{value: true}}
      %Evaluator.Null{} -> {:ok, %Evaluator.Boolean{value: true}}
      _ -> {:ok, %Evaluator.Boolean{value: false}}
    end
  end

  defp eval_prefix_expression("-", right) do
    case right do
      %Evaluator.Integer{value: val} -> {:ok, %Evaluator.Integer{value: -val}}
      _ -> {:ok, %Evaluator.Null{}}
    end
  end

  defp eval_prefix_expression(_, _) do
    {:ok, %Evaluator.Null{}}
  end

  defp eval_program([statement]) do
    case eval(statement) do
      {:ok, %Evaluator.Return{value: value}} -> {:ok, value}
      {:ok, value} -> {:ok, value}
    end
  end

  defp eval_program([statement | tail]) do
    case eval(statement) do
      {:ok, %Evaluator.Return{value: value}} -> {:ok, value}
      _ -> eval_program(tail)
    end
  end

  def eval_block_statements([statement]) do
    eval(statement)
  end
  
  def eval_block_statements([statement | tail]) do
    case eval(statement) do
      {:ok, %Evaluator.Return{} = value} -> {:ok, value}
      {:ok, _} -> eval_block_statements(tail)
    end
  end
end
