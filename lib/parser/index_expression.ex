defmodule Parser.IndexExpression do
  alias Lexer.Token

  defstruct token: %Token{}, left: %{}, index: %{}

  defimpl Parser.Expression, for: IndexExpression do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.IndexExpression  do
    def to_string(%Parser.IndexExpression{left: l, index: i}) do
      "(#{l}[#{i}])"
    end
  end
end
