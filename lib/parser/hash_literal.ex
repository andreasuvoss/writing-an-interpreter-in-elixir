defmodule Parser.HashLiteral do
  alias Lexer.Token

  defstruct token: %Token{type: :rbracket, literal: "{"}, pairs: %{}

  defimpl Parser.Expression, for: HashLiteral do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.HashLiteral  do
    def to_string(%Parser.HashLiteral{} = hl) do
      pairs = Map.keys(hl.pairs) |> Enum.map(fn k -> "#{k}: #{hl.pairs[k]}" end) |> Enum.join(", ")
      "{#{pairs}}"
    end
  end
end
