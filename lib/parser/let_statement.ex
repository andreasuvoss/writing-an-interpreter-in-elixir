defmodule Parser.LetStatement do
  defstruct token: %Lexer.Token{type: :let, literal: "let"}, name: %{token: :ident, value: ""}, value: ""

  def new(ident, expression) do
    %Parser.LetStatement{name: %{token: :ident, value: ident}, value: expression}
  end

  defimpl Parser.Statement, for: Parser.LetStatement do
    def token_literal(%Parser.LetStatement{token: token}) do
      token.literal
    end

    def token_literal(%{token: :ident, value: ident}) do
      ident
    end

    def expression_node() do
      nil
    end


    def node(_) do
      
    end
  end
  
end
