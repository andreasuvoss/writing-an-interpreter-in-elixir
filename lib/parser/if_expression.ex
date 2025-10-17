defmodule Parser.IfExpression do
  alias Lexer.Token
  alias Parser.BlockStatement

  defstruct token: %Token{type: :if, literal: "if"}, condition: %{}, consequence: %BlockStatement{}, alternative: nil

  defimpl Parser.Expression, for: IfExpression do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.IfExpression  do
    def to_string(%Parser.IfExpression{alternative: nil} = expr) do
      "if #{expr.condition} #{expr.consequence}"
    end

    def to_string(%Parser.IfExpression{} = expr) do
      "if #{expr.condition} #{expr.consequence} else #{expr.alternative}"
    end
  end
end
