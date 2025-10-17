defmodule Parser.PrefixExpression do
  alias Lexer.Token

  defstruct token: %Token{}, operator: "", right: %{}

  defimpl Parser.Expression, for: PrefixExpression do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.PrefixExpression  do
    def to_string(expression) do
      "(#{expression.operator}#{expression.right})"
    end
  end
end
