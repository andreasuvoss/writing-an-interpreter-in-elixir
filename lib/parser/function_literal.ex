defmodule Parser.FunctionLiteral do
  alias Parser.BlockStatement
  alias Lexer.Token

  defstruct token: %Token{type: :function, literal: "fn"}, parameters: [], body: %BlockStatement{}

  defimpl Parser.Expression, for: FunctionLiteral do
    def token_literal(expression) do
      expression.token.literal
    end

    def expression_node(_) do
    end
  end

  defimpl String.Chars, for: Parser.FunctionLiteral  do
    def to_string(%Parser.FunctionLiteral{} = fl) do
      params = fl.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      "#{fl.token.literal}(#{params}) #{fl.body}"
    end
  end
end
