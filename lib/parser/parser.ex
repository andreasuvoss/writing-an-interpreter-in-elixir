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
    case parse_statements(tokens, [], []) do
      {:ok, statements, _} -> {:ok, %Parser.Program{statements: Enum.reverse(statements)}}
      {:error, errors, _} -> {:error, errors |> Enum.reverse()}
    end
  end

  def parse_statements([], acc, []), do: {:ok, acc, []}
  def parse_statements([], _, errors), do: {:error, errors, []}
  def parse_statements([%Token{type: :eof} | _], acc, []), do: {:ok, acc, []}
  def parse_statements([%Token{type: :eof} | tail], _, errors), do: {:error, errors, tail} 
  def parse_statements([%Token{type: :semicolon} | tail], acc, errors), do: parse_statements(tail, acc, errors)

  def parse_statements([%Token{type: :let} | tail], acc, errors) do
    case parse_let_statement(tail) do
      {:ok, stmt, rest} -> parse_statements(rest, [stmt | acc], errors)
      {:error, errs, rest} -> parse_statements(rest, acc, errs ++ errors)
    end
  end

  def parse_statements([%Token{type: :return} | tail], acc, errors) do
    case parse_return_statement(tail) do
      {:ok, stmt, rest} -> parse_statements(rest, [stmt | acc], errors)
      {:error, errs, rest} -> parse_statements(rest, acc, errs ++ errors)
    end
  end

  def parse_statements([%Token{type: _} = head | tail], acc, errors) do
    case parse_expression_statement([head | tail]) do
      {:ok, stmt, rest} -> parse_statements(rest, [stmt | acc], errors)
      {:error, errs, rest} -> parse_statements(rest, acc, errs ++ errors)
    end
  end

  def parse_expression_statement([head | tail]) do
    case parse_expression([head | tail]) do
      {:ok, expr, [%Token{type: :semicolon} | tl]} -> {:ok, %Parser.ExpressionStatement{expression: expr}, tl}
      {:ok, expr, tl} -> {:ok, %Parser.ExpressionStatement{expression: expr}, tl}
      {:error, errors, tl} -> {:error, errors, tl}
    end
  end

  defp parse_let_statement([%Token{type: :ident, literal: name}, %Token{type: :assign} | tokens_tail]) do
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

  defp parse_let_statement([%Token{type: :eof} | tail]), do: {:error, ["expected identifier after let statement"], tail}
  defp parse_let_statement([%Token{type: :ident} = token | tail]), do: {:error, ["expected '=' after let #{token.literal}"], tail}
  defp parse_let_statement([token | tail]), do: {:error, ["unexpected symbol '#{token.literal}' in let statement"], tail}
  defp parse_let_statement([]), do: {:error, ["expected identifier after let statement"], []}

  defp parse_return_statement([]), do: {:error, ["expected expression after return"], []}
  defp parse_return_statement([%Token{type: :eof} | tail]), do: {:error, ["expected expression after return"], tail}

  defp parse_return_statement(tokens) do
    case parse_expression(tokens) do
      {:ok, value, rest} -> {:ok, %ReturnStatement{return_value: value}, rest}
      {:error, errors, rest} -> {:error, errors, rest}
    end
  end

  def parse_identifier([%Token{type: :ident} = token | tail]) do
    {:ok, %Identifier{token: token, value: token.literal}, tail}
  end

  def parse_integer_literal([%Token{type: :int} = token | tail]) do
    {:ok, %IntegerLiteral{token: token, value: String.to_integer(token.literal)}, tail}
  end

  def parse_boolean([%Token{type: true} = token | tail]) do
    {:ok, %Boolean{token: token, value: true}, tail}
  end

  def parse_boolean([%Token{type: false} = token | tail]) do
    {:ok, %Boolean{token: token, value: false}, tail}
  end

  def parse_prefix_expression([%Token{} = token | tail]) do
    case parse_expression(tail, :prefix) do
      {:ok, right, tl} -> {:ok, %PrefixExpression{token: token, operator: token.literal, right: right}, tl}
      {:error, errors, tl} -> {:error, errors, tl}
    end
  end

  def parse_grouped_expression([%Token{type: :lparen} | tail]) do
    case parse_expression(tail, :lowest) do
     {:ok, expr, [peek_token | rest]} -> 
        if peek_token.type != :rparen do
          {:error, ["expected ')' to close grouped expression got '#{peek_token.literal}' instead"], rest}
        else
          {:ok, expr, rest}
        end
      {:ok, _, []} -> {:error, ["unclosed grouped expression"], []}
      {:error, errors, rest} -> {:error, errors, rest}
    end
  end

  def parse_block_statement([token | tail], block_tokens \\ []) do
    case token.type do
      :lbrace ->
        parse_block_statement(tail)
      :eof ->
        {:error, ["block statement never terminated with '}'"], tail}
      :rbrace ->
        case parse_statements(Enum.reverse(block_tokens), [], []) do
          {:ok, statements, _} -> {:ok, %BlockStatement{statements: Enum.reverse(statements)}, tail}
          {:error, errors, _} -> {:error, errors, tail}
        end
      _ ->
        parse_block_statement(tail, [token | block_tokens])
    end
  end

  def parse_if_expression([token, peek_token | rest]) do
    if peek_token.type != :lparen do
      {:error, ["expected '(' to start if expression got '#{peek_token.literal}'"], rest}
    else
      case parse_expression(rest, :lowest) do
        {:ok, condition, [%Token{type: :rparen}, %Token{type: :lbrace} = peek_token | tail]} ->
          case parse_block_statement([peek_token | tail]) do
            {:ok, consequence, [%Token{type: :else} | tail]} ->
              case parse_block_statement(tail) do
                {:ok, alternative, tail} -> {:ok, %IfExpression{token: token, condition: condition, consequence: consequence, alternative: alternative }, tail}
                {:error, errors, tail} -> {:error, errors, tail}
              end
            {:ok, consequence, tail} -> {:ok, %IfExpression{ token: token, condition: condition, consequence: consequence }, tail}
            {:error, errors, tail} -> 
              IO.inspect(tail)
              {:error, errors, tail}
          end
        {:error, errors, tail} -> {:error, errors, tail}
      end
    end
  end

  def parse_function_literal([_, peek_token | rest]) do
    if peek_token.type != :lparen do
      {:error, ["expected '(' to start function literal got '#{peek_token.literal}'"], rest}
    else
      case parse_function_parameters(rest) do
       {:ok, params, rest} -> case parse_block_statement(rest) do
          {:ok, statements, rest} -> {:ok, %FunctionLiteral{parameters: params, body: statements}, rest}
          {:error, errors, rest} -> {:error, errors, rest}
       end
      {:error, errors, rest} -> {:error, errors, rest}
      end
    end
  end

  defp parse_function_parameters(a, acc \\ [])
  defp parse_function_parameters([token | tokens], acc) do
    case token.type do
      :rparen -> {:ok, Enum.reverse(acc), tokens}
      :comma -> parse_function_parameters(tokens, acc)
      :ident -> 
        case parse_identifier([token | tokens]) do
          {:ok, identifier, tokens} -> parse_function_parameters(tokens, [identifier | acc])
        end
      _ -> {:error, ["unexpected symbol '#{token.literal}' (#{token.type}) in function parameters"], tokens}
    end
  end
  defp parse_function_parameters([], _), do: {:error, ["could not parse function parameters for function literal"], []}

  defp parse_call_expression(function, [token | rest]) do
    if token.type != :lparen do
      {:error, ["expected '(' to start call expression got '#{token.literal}'"], rest}
    else
      case parse_call_arguments(rest) do
        {:ok, args, rest} -> {:ok, %CallExpression{token: token, function: function, arguments: args}, rest}
        {:error, errors, rest} -> {:error, errors, rest}
      end
    end
  end

  defp parse_call_arguments(a, acc \\ [])
  defp parse_call_arguments([token | tokens], acc) do
    case token.type do
      :rparen -> {:ok, Enum.reverse(acc), tokens}
      :comma -> parse_call_arguments(tokens, acc)
      _ -> 
        case parse_expression([token | tokens], :lowest) do
          {:ok, expr, tokens} -> parse_call_arguments(tokens, [expr | acc])
          {:error, errors, tail} -> {:error, errors, tail}
        end
    end
  end
  defp parse_call_arguments([], _), do: {:error, ["could not parse call arguments for call expression"], []}

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
  defp parse_prefix([%Token{type: :assign} | tail]), do: {:error, ["assignment '=' without let statement is not allowed"], tail}
  defp parse_prefix([%Token{literal: literal} | tail]), do: {:error, ["cannot handle symbol '#{literal}' in the current context"], tail}

  def parse_infix_expression(node, [], _), do: {:ok, node, []}
  def parse_infix_expression(node, [%Token{type: :eof} | _], _), do: {:ok, node, []}

  def parse_infix_expression(left, [%Token{} = token | tail] = rest, precedence) do
    current_precedence = precedence_of(token)

    # TODO: Might be something about a semicolon here?
    # if current_precedence > precedence and infix_operator?(token) and token.type != :semicolon do
    if current_precedence > precedence and infix_operator?(token) do
      if token.type == :lparen do
        parse_call_expression(left, [token | tail])
      else
        case parse_expression(tail, decode(current_precedence)) do
          {:ok, right, rest} ->  
            infix = %InfixExpression{token: token, left: left, operator: token.literal, right: right}
            parse_infix_expression(infix, rest, precedence)
          {:error, errors, rest} -> {:error, errors, rest}
        end
      end
    else
      {:ok, left, rest}
    end
  end

  def parse_expression(tokens, precedence \\ :_) do
    case parse_prefix(tokens) do
      {:ok, left, rest} -> parse_infix_expression(left, rest, encode(precedence))
      {:error, errors, rest} -> {:error, errors, rest}
    end
  end

  def infix_operator?(%Token{type: t}) do
    t in [:plus, :minus, :asterix, :slash, :gt, :lt, :eq, :not_eq, :lparen]
  end
end
