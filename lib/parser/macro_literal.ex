defmodule Parser.MacroLiteral do
  alias Parser.BlockStatement
  alias Lexer.Token

  defstruct token: %Token{type: :macro, literal: "macro"}, parameters: [], body: %BlockStatement{}

  defimpl Parser.Expression, for: MacroLiteral do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.MacroLiteral  do
    def to_string(%Parser.MacroLiteral{} = fl) do
      params = fl.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      "#{fl.token.literal}(#{params}) #{fl.body}"
    end
  end
end
