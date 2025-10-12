defmodule Parser.ReturnStatement do
  defstruct token: %Lexer.Token{type: :return, literal: "return"}, return_value: ""

  # def new(ident, expression) do
  #   %Parser.ReturnStatement{name: %{token: :ident, value: ident}, value: expression}
  # end

  defimpl Parser.Statement, for: Parser.ReturnStatement do
    def token_literal(%Parser.ReturnStatement{token: token}) do
      token.literal
    end

    def expression_node() do
      nil
    end


    def node(_) do
      
    end
  end
  
end
