defmodule Parser.ArrayLiteral do
  alias Lexer.Token

  defstruct token: %Token{type: :rbracket, literal: "["}, elements: []

  defimpl Parser.Expression, for: ArrayLiteral do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.ArrayLiteral  do
    def to_string(%Parser.ArrayLiteral{} = al) do
      elements = al.elements |> Enum.map(fn e -> "#{e}" end) |> Enum.join(", ")
      "[#{elements}]"
    end
  end
end
