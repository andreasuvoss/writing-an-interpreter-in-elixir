defmodule Parser.InfixExpression do
  alias Lexer.Token

  defstruct token: %Token{}, left: %{}, operator: "", right: %{}

  defimpl Parser.Expression, for: InfixExpression do
    def token_literal(expression) do
      expression.token.literal
    end

    def string(expression) do
      "(#{string(expression.left)} #{expression.operator} #{string(expression.right)})"
    end

    def expression_node(node) do
    end
  end
end
