defmodule AST.Identifier do
  defstruct token: %Lexer.Token{type: :ident, literal: ""}, value: ""

  defimpl AST.Expression, for: AST.Identifier do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.Identifier do
    def to_string(%AST.Identifier{value: value}) do
      "#{value}"
    end
    
  end
end
