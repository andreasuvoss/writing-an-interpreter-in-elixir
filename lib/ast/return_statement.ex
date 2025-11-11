defmodule AST.ReturnStatement do
  defstruct token: %Lexer.Token{type: :return, literal: "return"}, return_value: nil

  defimpl AST.Statement, for: AST.ReturnStatement do
    def token_literal(%AST.ReturnStatement{token: token}) do
      token.literal
    end
  end

  defimpl String.Chars, for: AST.ReturnStatement do
    def to_string(%AST.ReturnStatement{token: token, return_value: nil}) do
      "#{token.literal};"
    end

    def to_string(%AST.ReturnStatement{token: token, return_value: return_value}) do
      "#{token.literal} #{return_value};"
    end
  end
end
