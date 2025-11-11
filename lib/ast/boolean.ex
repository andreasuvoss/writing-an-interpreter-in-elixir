defmodule AST.Boolean do
  defstruct token: %Lexer.Token{type: :true, literal: "true"}, value: true

  defimpl AST.Expression, for: AST.Boolean do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.Boolean do
    def to_string(%AST.Boolean{token: %Lexer.Token{literal: literal}}) do
      "#{literal}"
    end
  end
end
