defmodule Parser.StringLiteral do
  alias Lexer.Token
  defstruct token: %Token{type: :string, literal: ""}, value: ""

  defimpl Parser.Expression, for: StringLiteral do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.StringLiteral do
    def to_string(%Parser.StringLiteral{value: value}) do
      "#{value}"
    end
  end
end
