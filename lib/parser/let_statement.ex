defmodule Parser.LetStatement do
  alias Parser.Identifier
  defstruct token: %Lexer.Token{type: :let, literal: "let"}, name: %Identifier{token: %Lexer.Token{type: :ident, literal: ""}, value: ""}, value: nil

  defimpl Parser.Statement, for: Parser.LetStatement do
    def token_literal(%Parser.LetStatement{token: token}) do
      token.literal
    end

    def string(%Parser.LetStatement{token: token, name: name, value: nil}) do
      "#{token.literal} #{name.token.literal} = ;"
    end

    def string(%Parser.LetStatement{token: token, name: name, value: value}) do
      "#{token.literal} #{name.token.literal} = #{value};"
    end

    def statement_node(_) do
      nil
    end
  end
  
end
