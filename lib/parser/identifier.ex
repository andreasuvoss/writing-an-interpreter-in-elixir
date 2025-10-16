defmodule Parser.Identifier do
  alias Lexer.Token
  defstruct token: %Token{type: :ident, literal: ""}, value: ""

  defimpl String.Chars, for: Parser.Identifier do
    def to_string(%Parser.Identifier{value: value}) do
      "#{value}"
    end
    
  end
end
