defmodule Parser.Parser do
  alias Parser.PrefixExpression
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
    # IO.inspect(statements)

    %Parser.Program{statements: Enum.reverse(statements)}
  end

  def parse_statements([], acc), do: {acc, []}
  def parse_statements([%Token{type: :eof} | _], acc), do: {acc, []}
  def parse_statements([%Token{type: :semicolon} | tail], acc), do: parse_statements(tail, acc)

  def parse_statements([%Token{type: :let} | tail], acc) do
    # IO.puts("parsing let")
    case parse_let_statement(tail) do
      {:ok, stmt, rest} -> parse_statements(rest, [stmt | acc])
      {:error, err} -> raise err
    end
  end

  def parse_statements([%Token{type: :return} | tail], acc) do
    # IO.puts("parsing return")
    case parse_return_statement(tail) do
      {:ok, stmt, rest} -> parse_statements(rest, [stmt | acc])
      {:error, err} -> raise err
    end
  end

  def parse_statements([%Token{type: _} = head | tail], acc) do
    # IO.puts("parsing exp")
    case parse_expression_statement([head | tail]) do
      {:ok, stmt, rest} ->
        parse_statements(rest, [stmt | acc])
        # {:error, err} -> raise err
    end
  end

  def parse_expression_statement([head | tail]) do
    # IO.inspect([head | tail])
    case parse_expression([head | tail]) do
      {_, expr, [%Token{type: :semicolon} | tl]} ->
        {:ok, %Parser.ExpressionStatement{expression: expr}, tl}

      {_, expr, tl} ->
        {:ok, %Parser.ExpressionStatement{expression: expr}, tl}
        # {_, expr, tl} -> 
        #  # IO.inspect(tl)
        #  {:ok, %Parser.ExpressionStatement{expression: expr}, tl}
    end

    # {_, expr, tl} = parse_expression([head | tail])
    # {:ok, %Parser.ExpressionStatement{expression: expr}, tl}
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

      _ ->
        {:error, "some error"}
    end
  end

  def parse_let_statement([%Token{type: :eof} | _]), do: {:error, "nothing after let statement"}

  def parse_let_statement([%Token{type: :ident}, _ | _]),
    do: {:error, "nothing after let statement"}

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
    # IO.puts("parsing identifier")
    {:ok, %Identifier{token: token, value: token.literal}, tail}
  end

  def parse_integer_literal([%Token{type: :int} = token | tail]) do
    # IO.puts("int")
    {:ok, %IntegerLiteral{token: token, value: String.to_integer(token.literal)}, tail}
  end

  def parse_prefix_expression([%Token{} = token | tail]) do
    {_, right, tl} = parse_expression(tail, :prefix)
    {:ok, %PrefixExpression{token: token, operator: token.literal, right: right}, tl}
  end

  def parse_infix_expression(left, [token | tail]) do

    

  end

  # TODO: Everything is a god damn prefix in this town (:
  def parse_expression([token, peek_token | tokens_tail], precedence \\ :_) do
    IO.puts(token.type)

    case token.type do
      :ident ->
        parse_identifier([token | tokens_tail])

      :int ->
        parse_integer_literal([token, peek_token | tokens_tail])

      :bang ->
        parse_prefix_expression([token, peek_token | tokens_tail])

      :minus ->
        parse_prefix_expression([token, peek_token | tokens_tail])

      :semicolon ->
        {:ok, [peek_token | tokens_tail]}
        # _ -> parse_expression([peek_token | tokens_tail])
    end
  end

  def infix_operator?(%Token{type: t}) do
    t in [:plus, :minus, :asterix, :slash, :gt, :th, :eq, :not_eq]
  end

end
