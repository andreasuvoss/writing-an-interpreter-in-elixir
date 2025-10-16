defmodule Parser.IntegerLiteral do
  alias Lexer.Token
  defstruct token: %Token{type: :int, literal: "0"}, value: 0

  defimpl Parser.Expression, for: IntegerLiteral do
    def token_literal(expression) do
      expression.token.literal
    end

    def string(expression) do
      expression.value
    end

    def expression_node(node) do
    end
  end

  defimpl String.Chars, for: Parser.IntegerLiteral do
    def to_string(%Parser.IntegerLiteral{value: value}) do
      value
    end
  end
end
