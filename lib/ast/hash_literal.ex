defmodule AST.HashLiteral do
  defstruct token: %Lexer.Token{type: :rbracket, literal: "{"}, pairs: %{}

  defimpl AST.Expression, for: AST.HashLiteral do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.HashLiteral do
    def to_string(%AST.HashLiteral{} = hl) do
      pairs = Map.keys(hl.pairs) |> Enum.map(fn k -> "#{k}: #{hl.pairs[k]}" end) |> Enum.join(", ")
      "{#{pairs}}"
    end
  end
end
