defmodule Parser.Parser do
  alias Parser.LetStatement
  alias Parser.ReturnStatement

  def parse_program(tokens) do
    %Parser.Program{statements: parse_statement(tokens)}
  end

  def parse_statement(tokens) do
    token = Enum.at(tokens, 0)

    statements = case token.type do
      :let -> tokens |> Enum.slice(1..length(tokens)) |> parse_let_statement()
      :return -> tokens |> Enum.slice(1..length(tokens)) |> parse_return_statement() 
      :eof -> []
    end

    statements
  end

  def parse_let_statement(tokens) do
    ident_token = Enum.at(tokens, 0)

    # TODO: better error handling 
    if ident_token.type != :ident do
      raise "missing identifier"
    end

    if Enum.at(tokens, 1).type != :assign do
      raise "missing equals sign"
    end

    # TODO: Skipping expressions until we encounter a semicolon
    tokens = tokens |> Enum.slice(2..length(tokens)) |> parse_expression()

    [%LetStatement{name: %{token: :ident, value: ident_token.literal}, value: ""} | parse_statement(tokens)]

  end

  def parse_return_statement(tokens) do
    # TODO: Skipping expressions until we encounter a semicolon
    tokens = tokens |> parse_expression()
    [%ReturnStatement{return_value: ""} | parse_statement(tokens)]

  end

  def parse_expression(tokens) do
    case Enum.at(tokens, 0).type do
      :semicolon -> tokens |> Enum.slice(1..length(tokens))
      _ -> tokens |> Enum.slice(1..length(tokens)) |> parse_expression()
    end
  end
end
