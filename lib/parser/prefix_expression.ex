defmodule Parser.PrefixExpression do
  alias Lexer.Token

  defstruct token: %Token{}, operator: "", right: %{}

  defimpl Parser.Expression, for: PrefixExpression do
    def token_literal(expression) do
      expression.token.literal
    end

    def string(expression) do
      "(#{expression.operator}#{string(expression.right)})"
    end

    def expression_node(node) do
    end
  end
end
