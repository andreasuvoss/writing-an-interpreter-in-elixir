defmodule Lexer.Token do
  # @typedoc "Type of token"
  # @type token_type() :: String.t()

  defstruct type: "", literal: ""

  @types %{
    illegal: "ILLEGAL",
    eof: "EOF",
    ident: "IDENT",
    int: "INT",
    assign: "=",
    plus: "+",
    comma: ",",
    semicolon: ";",
    lparen: "(",
    rparen: ")",
    lbrace: "{",
    rbrace: "}",
    function: "FUNCTION",
    let: "LET",
  }

  def get_token(token) do
    @types[token]
  end

  def lookup_identifier(identifier) do
    case identifier do
      "fn" -> %{type: :function, literal: identifier}
      "let" -> %{type: :let, literal: identifier}
      "return" -> %{type: :return, literal: identifier}
      "if" -> %{type: :if, literal: identifier}
      "else" -> %{type: :else, literal: identifier}
      "true" -> %{type: :true, literal: identifier}
      "false" -> %{type: :false, literal: identifier}
      _ -> %{type: :ident, literal: identifier}
    end
  end
end
