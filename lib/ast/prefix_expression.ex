defmodule AST.PrefixExpression do
  defstruct token: %Lexer.Token{}, operator: "", right: %{}

  defimpl AST.Expression, for: AST.PrefixExpression do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.PrefixExpression  do
    def to_string(expression) do
      "(#{expression.operator}#{expression.right})"
    end
  end
end
