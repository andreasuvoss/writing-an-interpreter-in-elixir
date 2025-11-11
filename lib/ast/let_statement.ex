defmodule AST.LetStatement do
  defstruct token: %Lexer.Token{type: :let, literal: "let"}, name: %AST.Identifier{token: %Lexer.Token{type: :ident, literal: ""}, value: ""}, value: nil

  defimpl AST.Statement, for: AST.LetStatement do
    def token_literal(%AST.LetStatement{token: token}) do
      token.literal
    end
  end

  defimpl String.Chars, for: AST.LetStatement do
    def to_string(%AST.LetStatement{token: token, name: name, value: nil}) do
      "#{token.literal} #{name.token.literal} = ;"
    end

    def to_string(%AST.LetStatement{token: token, name: name, value: value}) do
      "#{token.literal} #{name.token.literal} = #{value};"
    end
  end
  
end
