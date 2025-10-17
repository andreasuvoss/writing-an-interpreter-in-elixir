defmodule Parser.BlockStatement do
  defstruct token: %Lexer.Token{type: :lbrace, literal: "{"}, statements: []

  defimpl Parser.Statement, for: Parser.BlockStatement do
    def token_literal(%Parser.BlockStatement{token: token}) do
      token.literal
    end

    def statement_node(_) do
      nil
    end
  end

  defimpl String.Chars, for: Parser.BlockStatement do
    def to_string(%Parser.BlockStatement{statements: stmts}) do
      stmts |> Enum.map(fn s -> "#{s}" end) |> Enum.join("")
    end
  end
  
end
