defmodule AST.CallExpression do
  defstruct token: %Lexer.Token{}, function: %{}, arguments: []

  defimpl AST.Expression, for: AST.CallExpression do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.CallExpression  do
    def to_string(%AST.CallExpression{} = ce) do
      args = ce.arguments |> Enum.map(fn a -> "#{a}" end) |> Enum.join(", ")

      "#{ce.function}(#{args})"
    end
  end
end
