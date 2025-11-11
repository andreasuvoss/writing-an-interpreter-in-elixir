defmodule AST.IndexExpression do
  defstruct token: %Lexer.Token{}, left: %{}, index: %{}

  defimpl AST.Expression, for: AST.IndexExpression do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.IndexExpression  do
    def to_string(%AST.IndexExpression{left: l, index: i}) do
      "(#{l}[#{i}])"
    end
  end
end
