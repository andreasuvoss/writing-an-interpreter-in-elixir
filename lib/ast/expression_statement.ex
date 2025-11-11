defmodule AST.ExpressionStatement do
  defstruct token: %Lexer.Token{type: :expression, literal: nil}, expression: ""

  defimpl AST.Statement, for: AST.ExpressionStatement do
    def token_literal(%AST.ExpressionStatement{token: token}) do
      token.literal
    end
  end

  defimpl String.Chars, for: AST.ExpressionStatement do
    def to_string(%AST.ExpressionStatement{expression: nil}) do
      ""
    end

    def to_string(%AST.ExpressionStatement{expression: exp}) do
      "#{exp}"
    end
  end
  
end
