defmodule AST.StringLiteral do
  defstruct token: %Lexer.Token{type: :string, literal: ""}, value: ""

  defimpl AST.Expression, for: AST.StringLiteral do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.StringLiteral do
    def to_string(%AST.StringLiteral{value: value}) do
      "#{value}"
    end
  end
end
