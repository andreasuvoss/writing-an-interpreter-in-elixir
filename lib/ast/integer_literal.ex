defmodule AST.IntegerLiteral do
  defstruct token: %Lexer.Token{type: :int, literal: "0"}, value: 0

  defimpl AST.Expression, for: AST.IntegerLiteral do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.IntegerLiteral do
    def to_string(%AST.IntegerLiteral{value: value}) do
      "#{value}"
    end
  end
end
