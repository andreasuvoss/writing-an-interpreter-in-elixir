defmodule Parser.CallExpression do
  alias Lexer.Token

  defstruct token: %Token{}, function: %{}, arguments: []

  defimpl Parser.Expression, for: CallExpression do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.CallExpression  do
    def to_string(%Parser.CallExpression{} = ce) do
      args = ce.arguments |> Enum.map(fn a -> "#{a}" end) |> Enum.join(", ")

      "#{ce.function}(#{args})"
    end
  end
end
