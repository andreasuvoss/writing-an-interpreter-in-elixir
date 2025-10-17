defmodule Parser.ReturnStatement do
  defstruct token: %Lexer.Token{type: :return, literal: "return"}, return_value: nil

  defimpl Parser.Statement, for: Parser.ReturnStatement do
    def token_literal(%Parser.ReturnStatement{token: token}) do
      token.literal
    end

    def statement_node(_) do
      nil
    end
  end

  defimpl String.Chars, for: Parser.ReturnStatement do
    def to_string(%Parser.ReturnStatement{token: token, return_value: nil}) do
      "#{token.literal} ;"
    end

    def to_string(%Parser.ReturnStatement{token: token, return_value: return_value}) do
      "#{token.literal} #{return_value};"
    end
  end
end
