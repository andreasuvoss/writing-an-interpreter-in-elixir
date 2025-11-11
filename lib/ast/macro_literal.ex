defmodule AST.MacroLiteral do
  defstruct token: %Lexer.Token{type: :macro, literal: "macro"}, parameters: [], body: %AST.BlockStatement{}

  defimpl AST.Expression, for: AST.MacroLiteral do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.MacroLiteral  do
    def to_string(%AST.MacroLiteral{} = fl) do
      params = fl.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      "#{fl.token.literal}(#{params}) #{fl.body}"
    end
  end
end
