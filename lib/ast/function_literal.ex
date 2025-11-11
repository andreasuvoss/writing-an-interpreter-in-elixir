defmodule AST.FunctionLiteral do
  defstruct token: %Lexer.Token{type: :function, literal: "fn"}, parameters: [], body: %AST.BlockStatement{}

  defimpl AST.Expression, for: AST.FunctionLiteral do
    def token_literal(expression) do
      expression.token.literal
    end
  end

  defimpl String.Chars, for: AST.FunctionLiteral  do
    def to_string(%AST.FunctionLiteral{} = fl) do
      params = fl.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      "#{fl.token.literal}(#{params}) #{fl.body}"
    end
  end
end
