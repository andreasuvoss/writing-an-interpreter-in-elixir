defmodule AST.IfExpression do
  defstruct token: %Lexer.Token{type: :if, literal: "if"}, condition: %{}, consequence: %AST.BlockStatement{}, alternative: nil

  defimpl AST.Expression, for: AST.IfExpression do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.IfExpression  do
    def to_string(%AST.IfExpression{alternative: nil} = expr) do
      "if #{expr.condition} #{expr.consequence}"
    end

    def to_string(%AST.IfExpression{} = expr) do
      "if #{expr.condition} #{expr.consequence} else #{expr.alternative}"
    end
  end
end
