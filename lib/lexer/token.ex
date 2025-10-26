# TODO: Look into how this can be 

defmodule Lexer.Token do
  # @typedoc "Type of token"
  # @type token_type() :: String.t()

  defstruct type: "", literal: ""

  # @types %{
  #   illegal: "ILLEGAL",
  #   eof: "EOF",
  #   ident: "IDENT",
  #   int: "INT",
  #   assign: "=",
  #   plus: "+",
  #   comma: ",",
  #   semicolon: ";",
  #   lparen: "(",
  #   rparen: ")",
  #   lbrace: "{",
  #   rbrace: "}",
  #   function: "FUNCTION",
  #   let: "LET",
  # }
  #
  # def get_token(token) do
  #   @types[token]
  # end

  def lookup_identifier(identifier) do
    case identifier do
      "fn" -> %Lexer.Token{type: :function, literal: identifier}
      "let" -> %Lexer.Token{type: :let, literal: identifier}
      "return" -> %Lexer.Token{type: :return, literal: identifier}
      "if" -> %Lexer.Token{type: :if, literal: identifier}
      "else" -> %Lexer.Token{type: :else, literal: identifier}
      "true" -> %Lexer.Token{type: :true, literal: identifier}
      "false" -> %Lexer.Token{type: :false, literal: identifier}
      _ -> %Lexer.Token{type: :ident, literal: identifier}
    end
  end
end
