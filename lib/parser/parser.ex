defmodule Parser.Parser do
  alias Parser.CallExpression
  alias Parser.FunctionLiteral
  alias Parser.BlockStatement
  alias Parser.IfExpression
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
      :lparen -> encode(:call)
      _ -> encode(:lowest)
    end
  end

  def parse_program(tokens) do
    {statements, _, errors} = parse_statements(tokens, [], [])

    # IO.inspect(Enum.reverse(errors))

    program = %Parser.Program{statements: Enum.reverse(statements)}

    # IO.inspect(program)

    {:ok, program}
  end

  def parse_statements([], acc, errors), do: {acc, [], errors}
  def parse_statements([%Token{type: :eof} | _], acc, errors), do: {acc, [], errors}

  def parse_statements([%Token{type: :semicolon} | tail], acc, errors),
    do: parse_statements(tail, acc, errors)

  def parse_statements([%Token{type: :let} | tail], acc, errors) do
    case parse_let_statement(tail) do
      {:ok, stmt, tail} -> parse_statements(tail, [stmt | acc], errors)
      {:error, err, tail} -> parse_statements(tail, acc, err ++ errors)
    end
  end

  def parse_statements([%Token{type: :return} | tail], acc, errors) do
    case parse_return_statement(tail) do
      {:ok, stmt, tail} -> parse_statements(tail, [stmt | acc], errors)
      {:error, err, tail} -> parse_statements(tail, acc, err ++ errors)
    end
  end

  def parse_statements([%Token{type: _} = head | tail], acc, errors) do
    case parse_expression_statement([head | tail]) do
      {:ok, stmt, rest} -> parse_statements(rest, [stmt | acc], errors)
      {:error, _, err, tail} -> parse_statements(tail, acc, err ++ errors)
    end
  end

  def parse_expression_statement([head | tail]) do
    case parse_expression([head | tail]) do
      {:ok, expr, [%Token{type: :semicolon} | tl]} ->
        {:ok, %Parser.ExpressionStatement{expression: expr}, tl}

      {:ok, expr, tl} ->
        {:ok, %Parser.ExpressionStatement{expression: expr}, tl}

      {:error, expr, errors, tail} ->
        {:error, %Parser.ExpressionStatement{expression: expr}, errors, tail}
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

      {:error, _, errors, tail} ->
        {:error, errors, tail}
    end
  end

  def parse_let_statement([%Token{type: :eof} | tail]),
    do: {:error, ["expected identifier after let statement"], tail}

  def parse_let_statement([%Token{type: :ident} = token, _ | tail]),
    do: {:error, ["expected '=' after let #{token.literal}"], tail}

  def parse_let_statement([]), do: {:error, ["expected identifier after let statement"], []}

  def parse_return_statement([]), do: {:error, ["expected expression after return"], []}

  def parse_return_statement([%Token{type: :eof} | tail]),
    do: {:error, ["expected expression after return"], tail}

  def parse_return_statement([%Token{type: :semicolon} | tail]),
    do: {:error, ["expected expression after return"], tail}

  def parse_return_statement(tokens) do
    case parse_expression(tokens) do
      {:ok, value, rest} -> {:ok, %ReturnStatement{return_value: value}, rest}
      {:error, _, errors, rest} -> {:error, errors, rest}
    end
  end

  def parse_identifier([%Token{type: :ident} = token | tail]) do
    {:ok, %Identifier{token: token, value: token.literal}, tail}
  end

  def parse_integer_literal([%Token{type: :int} = token | tail]) do
    case Integer.parse(token.literal) do
      {int, ""} -> {:ok, %IntegerLiteral{token: token, value: int}, tail}
      _ -> {:error, ["could not parse #{token.literal} as int"], tail}
    end
  end

  def parse_boolean([%Token{type: true} = token | tail]) do
    {:ok, %Boolean{token: token, value: true}, tail}
  end

  def parse_boolean([%Token{type: false} = token | tail]) do
    {:ok, %Boolean{token: token, value: false}, tail}
  end

  def parse_prefix_expression([%Token{} = token | tail]) do
    {_, right, tl} = parse_expression(tail, :prefix)
    {:ok, %PrefixExpression{token: token, operator: token.literal, right: right}, tl}
  end

  def parse_grouped_expression([%Token{type: :lparen} | tail]) do
    # {_, expr, [peek_token | rest]} = parse_expression(tail, :lowest)
    case  parse_expression(tail, :lowest) do
      {_, expr, [peek_token | rest]} -> 
        if peek_token.type != :rparen do
          {:error, nil, ["expected ')' to finish grouped expression"], rest}
        else
          {:ok, expr, rest}
        end
        
    end
    # if peek_token.type != :rparen do
    #   {:ok, nil, rest}
    # else
    #   {:ok, expr, rest}
    # end
  end

  def parse_block_statement([token, peek_token | tail], block_tokens \\ []) do
    case token.type do
      :lbrace ->
        parse_block_statement([peek_token | tail])

      :eof ->
        raise ""

      :rbrace ->
        case parse_statements(Enum.reverse(block_tokens), [], []) do
          {statements, _, []} ->
            {:ok, %BlockStatement{statements: Enum.reverse(statements)}, [peek_token | tail]}

          {statements, _, errors} ->
            {:error, %BlockStatement{statements: Enum.reverse(statements)}, errors,
             [peek_token | tail]}

            # {_, _, errors} -> {:error, errors, [peek_token | tail]}
        end

      # {statements, _, errors} = parse_statements(Enum.reverse(block_tokens), [], [])
      # {:ok, %BlockStatement{statements: Enum.reverse(statements)}, [peek_token | tail]}
      _ ->
        parse_block_statement([peek_token | tail], [token | block_tokens])
    end
  end

  def parse_if_expression([token, peek_token | rest]) do
    if peek_token.type != :lparen do
      {:ok, nil, rest}
    else
      case parse_expression(rest, :lowest) do
        {:ok, condition, [%Token{type: :rparen}, %Token{type: :lbrace} = peek_token | tail]} ->
          case parse_block_statement([peek_token | tail]) do
            {:ok, consequence, [%Token{type: :else} | tail]} ->
              case parse_block_statement(tail) do
                {:ok, alternative, tail} ->
                  {:ok,
                   %IfExpression{
                     token: token,
                     condition: condition,
                     consequence: consequence,
                     alternative: alternative
                   }, tail}

                {:error, alternative, errors, tail} ->
                  {:error,
                   %IfExpression{
                     token: token,
                     condition: condition,
                     consequence: consequence,
                     alternative: alternative
                   }, errors, tail}
              end

            {:ok, consequence, tail} ->
              {:ok,
               %IfExpression{
                 token: token,
                 condition: condition,
                 consequence: consequence
               }, tail}

            {:error, consequence, errors, tail} ->
              {:error,
               %IfExpression{
                 token: token,
                 condition: condition,
                 consequence: consequence
               }, errors, tail}
          end

        {:ok, _, tail} ->
          {:ok, nil, tail}
      end
    end
  end

  def parse_function_literal([_, peek_token | rest]) do
    if peek_token.type != :lparen do
      {:error, nil, ["expected '(' after function literal fn"], rest}
      # {:ok, nil, rest}
    else
      case parse_function_parameters(rest) do
        {:ok, params, rest} ->
          case parse_block_statement(rest) do
            {:ok, statements, rest} ->
              {:ok, %FunctionLiteral{parameters: params, body: statements}, rest}
          end
        {:error, error, rest} -> {:error, nil, error, rest}

          # {:ok, statements, rest} = parse_block_statement(rest)
      end

      # {:ok, params, rest} = parse_function_parameters(rest)
      # {:ok, statements, rest} = parse_block_statement(rest)
      # {:ok, %FunctionLiteral{parameters: params, body: statements}, rest}
    end
  end

  defp parse_function_parameters([token | tokens], acc \\ []) do
    case token.type do
      :rparen ->
        {:ok, Enum.reverse(acc), tokens}

      :comma ->
        parse_function_parameters(tokens, acc)

      :ident ->
        {:ok, identifier, tokens} = parse_identifier([token | tokens])
        parse_function_parameters(tokens, [identifier | acc])

      _ ->
        {:error, ["error parsing function literal parameters"], tokens}
    end
  end

  defp parse_call_expression(function, [token | rest]) do
    if token.type != :lparen do
      {:ok, nil, rest}
    else
      # {:ok, args, rest} = parse_call_arguments(rest)
      case parse_call_arguments(rest) do
        {:ok, args, rest} -> {:ok, %CallExpression{token: token, function: function, arguments: args}, rest}
        {:error, _, errors, rest} -> {:error, nil, errors, rest}
      end
    end
  end

  defp parse_call_arguments([token | tokens], acc \\ []) do
    case token.type do
      :rparen ->
        {:ok, Enum.reverse(acc), tokens}

      :comma ->
        parse_call_arguments(tokens, acc)

      _ ->
        case parse_expression([token | tokens], :lowest) do
           {:ok, expr, tokens} -> parse_call_arguments(tokens, [expr | acc])
           {:error, _, errors, tail} -> {:error, nil, errors, tail}
        end
        # {:ok, expr, tokens} = parse_expression([token | tokens], :lowest)
        # parse_call_arguments(tokens, [expr | acc])
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
  defp parse_prefix([%Token{type: true} | _] = tokens), do: parse_boolean(tokens)
  defp parse_prefix([%Token{type: false} | _] = tokens), do: parse_boolean(tokens)
  defp parse_prefix([%Token{type: :if} | _] = tokens), do: parse_if_expression(tokens)
  defp parse_prefix([%Token{type: :function} | _] = tokens), do: parse_function_literal(tokens)

  defp parse_prefix([%Token{type: :assign} | tail]),
    do: {:error, nil, ["assignment '=' without let statement is not allowed"], tail}
  defp parse_prefix([%Token{literal: literal} | tail]),
    do: {:error, nil, ["cannot handle symbol '#{literal}' in the current context"], tail}

  defp parse_infix_expression(node, [], _), do: {:ok, node, []}
  defp parse_infix_expression(node, [%Token{type: :eof} | _], _), do: {:ok, node, []}
  defp parse_infix_expression(node, [%Token{type: :semicolon} | tail], _), do: {:ok, node, tail}

  defp parse_infix_expression(
         left,
         [%Token{} = token, %Token{} = peek_token | tail] = rest,
         precedence
       ) do
    current_precedence = precedence_of(token)

    if current_precedence > precedence and infix_operator?(token) do
      if token.type == :lparen do
        parse_call_expression(left, [token, peek_token | tail])
      else
        # {:ok, right, rest} = parse_expression([peek_token | tail], decode(current_precedence))
        case parse_expression([peek_token | tail], decode(current_precedence)) do
          {:ok, right, rest} ->  parse_infix_expression(%InfixExpression{token: token, left: left, operator: token.literal, right: right}, rest, precedence)
          {:error, _, errors, rest} -> {:error, nil, errors, rest}
        end
        # infix = %InfixExpression{token: token, left: left, operator: token.literal, right: right}
        # parse_infix_expression(infix, rest, precedence)
      end
    else
      {:ok, left, rest}
    end
  end

  def parse_expression(tokens, precedence \\ :_) do
    # {:ok, left, rest} = parse_prefix(tokens)
    case parse_prefix(tokens) do
      {:ok, left, rest} ->
        parse_infix_expression(left, rest, encode(precedence))

      {:error, left, errors, tail} ->
        {_, expr, tail} = parse_infix_expression(left, tail, encode(precedence))
        {:error, nil, errors, tail}
    end

    # parse_infix_expression(left, rest, encode(precedence))
  end

  def infix_operator?(%Token{type: t}) do
    t in [:plus, :minus, :asterix, :slash, :gt, :lt, :eq, :not_eq, :lparen]
  end
end
