defmodule Parser.Parser do
  alias Parser.Boolean
  alias Parser.PrefixExpression
  alias Parser.InfixExpression
  alias Parser.IntegerLiteral
  alias Lexer.Token
  alias Parser.LetStatement
  alias Parser.ReturnStatement
  alias Parser.Identifier

  precedence_constants = [
    _: 0,
    lowest: 1,
    equals: 2,
    lessgreater: 3,
    sum: 4,
    product: 5,
    prefix: 6,
    call: 7
  ]

  for {key, value} <- precedence_constants do
    def encode(unquote(key)), do: unquote(value)
    def decode(unquote(value)), do: unquote(key)
  end

  def precedence_of(%Token{type: type}) do
    case type do
      :eq -> encode(:equals)
      :not_eq -> encode(:equals)
      :lt -> encode(:lessgreater)
      :gt -> encode(:lessgreater)
      :plus -> encode(:sum)
      :minus -> encode(:sum)
      :slash -> encode(:product)
      :asterix -> encode(:product)
      _ -> encode(:lowest)
    end
  end

  def parse_program(tokens) do
    {statements, _} = parse_statements(tokens, [])

    %Parser.Program{statements: Enum.reverse(statements)}
  end

  def parse_statements([], acc), do: {acc, []}
  def parse_statements([%Token{type: :eof} | _], acc), do: {acc, []}
  def parse_statements([%Token{type: :semicolon} | tail], acc), do: parse_statements(tail, acc)

  def parse_statements([%Token{type: :let} | tail], acc) do
    case parse_let_statement(tail) do
      {:ok, stmt, rest} -> parse_statements(rest, [stmt | acc])
      {:error, err} -> raise err
    end
  end

  def parse_statements([%Token{type: :return} | tail], acc) do
    case parse_return_statement(tail) do
      {:ok, stmt, rest} -> parse_statements(rest, [stmt | acc])
      {:error, err} -> raise err
    end
  end

  def parse_statements([%Token{type: _} = head | tail], acc) do
    case parse_expression_statement([head | tail]) do
      {:ok, stmt, rest} ->
        parse_statements(rest, [stmt | acc])
    end
  end

  def parse_expression_statement([head | tail]) do
    case parse_expression([head | tail]) do
      {_, expr, [%Token{type: :semicolon} | tl]} -> {:ok, %Parser.ExpressionStatement{expression: expr}, tl}
      {_, expr, tl} -> {:ok, %Parser.ExpressionStatement{expression: expr}, tl}
    end
  end

  def parse_let_statement([
        %Token{type: :ident, literal: name},
        %Token{type: :assign} | tokens_tail
      ]) do
    case parse_expression(tokens_tail) do
      {:ok, value, rest} ->
        {:ok,
         %LetStatement{
           name: %Identifier{
             token: %Token{type: :ident, literal: name},
             value: name
           },
           value: value
         }, rest}
    end
  end

  def parse_let_statement([%Token{type: :eof} | _]), do: {:error, "nothing after let statement"}

  def parse_let_statement([%Token{type: :ident}, _ | _]), do: {:error, "nothing after let statement"}

  def parse_let_statement([]), do: {:error, "nothing after let statement"}

  def parse_return_statement([]), do: {:error, "nothing after return statement"}
  def parse_return_statement([%Token{type: :eof}]), do: {:error, "nothing after return statement"}

  def parse_return_statement(tokens) do
    case parse_expression(tokens) do
      {:ok, value, rest} -> {:ok, %ReturnStatement{return_value: value}, rest}
      _ -> {:error, "some error"}
    end
  end

  def parse_identifier([%Token{type: :ident} = token | tail]) do
    {:ok, %Identifier{token: token, value: token.literal}, tail}
  end

  def parse_integer_literal([%Token{type: :int} = token | tail]) do
    {:ok, %IntegerLiteral{token: token, value: String.to_integer(token.literal)}, tail}
  end

  def parse_boolean([%Token{type: :true} = token | tail]) do
    {:ok, %Boolean{token: token, value: true}, tail}
  end

  def parse_boolean([%Token{type: :false} = token | tail]) do
    {:ok, %Boolean{token: token, value: false}, tail}
  end

  def parse_prefix_expression([%Token{} = token | tail]) do
    {_, right, tl} = parse_expression(tail, :prefix)
    {:ok, %PrefixExpression{token: token, operator: token.literal, right: right}, tl}
  end


  def parse_grouped_expression([%Token{type: :lparen} | tail]) do
    {_, expr, [peek_token | rest]} = parse_expression(tail, :lowest)

    if peek_token.type != :rparen do
      {:ok, nil, rest}
    else
      {:ok, expr, rest}
    end
  end

  defp parse_prefix([%Token{type: :bang} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :minus} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :plus} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :gt} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :lt} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :eq} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :not_eq} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :lparen} | _] = tokens), do: parse_grouped_expression(tokens)
  defp parse_prefix([%Token{type: :int} | _] = tokens), do: parse_integer_literal(tokens)
  defp parse_prefix([%Token{type: :ident} | _] = tokens), do: parse_identifier(tokens)
  defp parse_prefix([%Token{type: :true} | _] = tokens), do: parse_boolean(tokens)
  defp parse_prefix([%Token{type: :false} | _] = tokens), do: parse_boolean(tokens)

  def parse_infix_expression(node, [], _), do: {:ok, node, []}
  def parse_infix_expression(node, [%Token{type: :eof} | _], _), do: {:ok, node, []}
  def parse_infix_expression(left, [%Token{} = token, %Token{} = peek_token | tail] = rest, precedence) do
    current_precedence = precedence_of(token)

    if current_precedence > precedence and infix_operator?(token) do
      {:ok, right, rest} = parse_expression([peek_token | tail], decode(current_precedence))
      infix = %InfixExpression{token: token, left: left, operator: token.literal, right: right}
      parse_infix_expression(infix, rest, precedence)
    else
      {:ok, left, rest}
    end
  end


  def parse_expression(tokens, precedence \\ :_) do

    {:ok, left, rest} = parse_prefix(tokens)

    parse_infix_expression(left, rest, encode(precedence))
  end

  def infix_operator?(%Token{type: t}) do
    t in [:plus, :minus, :asterix, :slash, :gt, :lt, :eq, :not_eq]
  end

end
