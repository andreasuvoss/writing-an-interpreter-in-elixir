defmodule Parser.Boolean do
  alias Lexer.Token
  defstruct token: %Token{type: :true, literal: "true"}, value: true

  defimpl Parser.Expression, for: Parser.Boolean do
    def token_literal(expression) do
      expression.token.literal
    end

    def string(expression) do
      expression.value
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.Boolean do
    def to_string(%Parser.Boolean{token: %Token{literal: literal}}) do
      "#{literal}"
    end
  end
end
