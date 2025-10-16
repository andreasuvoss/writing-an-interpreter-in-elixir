defmodule Parser.ExpressionStatement do
  defstruct token: %Lexer.Token{type: :expression, literal: nil}, expression: ""

  defimpl Parser.Statement, for: Parser.ExpressionStatement do
    def token_literal(%Parser.ExpressionStatement{token: token}) do
      token.literal
    end

    def string(%Parser.ExpressionStatement{expression: nil}) do
      ""
    end

    def string(%Parser.ExpressionStatement{expression: exp}) do
      exp
    end

    def statement_node(_) do
      nil
    end
  end
  
end
