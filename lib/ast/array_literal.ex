defmodule AST.ArrayLiteral do
  defstruct token: %Lexer.Token{type: :rbracket, literal: "["}, elements: []

  defimpl AST.Expression, for: AST.ArrayLiteral do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.ArrayLiteral do
    def to_string(%AST.ArrayLiteral{} = al) do
      elements = al.elements |> Enum.map(fn e -> "#{e}" end) |> Enum.join(", ")
      "[#{elements}]"
    end
  end
end
