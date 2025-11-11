defmodule AST.BlockStatement do
  defstruct token: %Lexer.Token{type: :lbrace, literal: "{"}, statements: []

  defimpl AST.Statement, for: AST.BlockStatement do
    def token_literal(%AST.BlockStatement{token: token}) do
      token.literal
    end
  end

  defimpl String.Chars, for: AST.BlockStatement do
    def to_string(%AST.BlockStatement{statements: stmts}) do
      stmts |> Enum.map(fn s -> "#{s}" end) |> Enum.join("")
    end
  end
end
