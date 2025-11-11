defmodule AST.InfixExpression do
  defstruct token: %Lexer.Token{}, left: %{}, operator: "", right: %{}

  defimpl AST.Expression, for: AST.InfixExpression do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.InfixExpression  do
    def to_string(%AST.InfixExpression{left: l, operator: op, right: r}) do
      "(#{l} #{op} #{r})"
    end
  end
end
