defmodule Parser.Parser do
  alias Parser.IndexExpression
  alias Parser.CallExpression
  alias Parser.FunctionLiteral
  alias Parser.BlockStatement
  alias Parser.IfExpression
  alias Parser.Boolean
  alias Parser.PrefixExpression
  alias Parser.InfixExpression
  alias Parser.IntegerLiteral
  alias Parser.StringLiteral
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
    call: 7,
    index: 8
  ]

  for {key, value} <- precedence_constants do
    defp encode(unquote(key)), do: unquote(value)
    defp decode(unquote(value)), do: unquote(key)
  end

  defp precedence_of(%Token{type: type}) do
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
      :lbracket -> encode(:index)
      _ -> encode(:lowest)
    end
  end

  def parse_program(tokens) do
    case parse_statements(tokens) do
      {:ok, statements} -> {:ok, %Parser.Program{statements: statements}}
      {:error, errors} -> {:error, errors}
    end
  end

  defp parse_statements(tokens, acc \\ [], errors \\ []) do
    case parse_statement(tokens) do
      {:ok, nil, []} -> case errors do
        [] -> {:ok, Enum.reverse(acc)}
        _ -> {:error, Enum.reverse(errors)}
      end
      {:ok, nil, remaining_tokens} -> parse_statements(remaining_tokens, acc, errors)
      {:ok, stmt, remaining_tokens} -> parse_statements(remaining_tokens, [stmt | acc], errors)
      {:error, errs, remaining_tokens} -> parse_statements(remaining_tokens, acc, errs ++ errors)
    end
  end

  defp parse_statement([]), do: {:ok, nil, []}
  defp parse_statement([%Token{type: :eof}]), do: {:ok, nil, []}
  defp parse_statement([%Token{type: :semicolon} | tail]), do: {:ok, nil, tail}
  defp parse_statement([%Token{type: :let} | tail]) do
    case parse_let_statement(tail) do
      {:ok, stmt, rest} -> {:ok, stmt, rest}
      {:error, errs, rest} -> {:error, errs, rest}
    end
  end
  defp parse_statement([%Token{type: :return} | tail]) do
    case parse_return_statement(tail) do
      {:ok, stmt, rest} -> {:ok, stmt, rest}
      {:error, errs, rest} -> {:error, errs, rest}
    end
  end
  defp parse_statement([%Token{type: _} | _] = tokens) do
    case parse_expression_statement(tokens) do
      {:ok, stmt, rest} -> {:ok, stmt, rest}
      {:error, errs, rest} -> {:error, errs, rest}
    end
  end

  defp parse_expression_statement([head | tail]) do
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
      {:error, errors, tail} -> {:error, errors, tail} 
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

  defp parse_identifier([%Token{type: :ident} = token | tail]) do
    {:ok, %Identifier{token: token, value: token.literal}, tail}
  end

  defp parse_integer_literal([%Token{type: :int} = token | tail]) do
    {:ok, %IntegerLiteral{token: token, value: String.to_integer(token.literal)}, tail}
  end

  defp parse_boolean([%Token{type: true} = token | tail]) do
    {:ok, %Boolean{token: token, value: true}, tail}
  end

  defp parse_boolean([%Token{type: false} = token | tail]) do
    {:ok, %Boolean{token: token, value: false}, tail}
  end

  defp parse_prefix_expression([%Token{} = token | tail]) do
    case parse_expression(tail, :prefix) do
      {:ok, right, tl} -> {:ok, %PrefixExpression{token: token, operator: token.literal, right: right}, tl}
      {:error, errors, tl} -> {:error, errors, tl}
    end
  end

  defp parse_grouped_expression([%Token{type: :lparen} | tail]) do
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

  defp parse_block_statement(tokens, acc \\ [], errors \\ [])
  defp parse_block_statement([%Token{} = token | tail], acc, errors) do
    case token.type do
      :lbrace -> parse_block_statement(tail)
      :rbrace -> 
        case errors do
          [] -> {:ok, %BlockStatement{statements: Enum.reverse(acc)}, tail}
          _ -> {:error, errors, tail}
        end
      :eof -> {:error, ["unterminated block statement"], tail}
      _ -> 
        case parse_statement([token | tail]) do 
          {:ok, nil, tail} -> parse_block_statement(tail, acc, errors)
          {:ok, stmt, tail} -> parse_block_statement(tail, [stmt | acc], errors)
          {:error, errs, tail} -> {:error, errs, tail}
        end
    end
  end

  defp parse_block_statement([%Token{type: :eof}], _, errors), do: {:error, ["unterminated block statement" | errors], []}

  defp parse_if_expression([token, peek_token | rest]) do
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
              {:error, errors, tail}
          end
        {:error, errors, tail} -> {:error, errors, tail}
        {:ok, condition, [_ | tail]} -> {:error, ["missing block for condition #{condition}"], tail}
      end
    end
  end

  defp parse_function_literal([token | rest]) do
    if token.type != :lparen do
      {:error, ["expected '(' to start function literal got '#{token.literal}'"], rest}
    else
      case parse_function_parameters(rest) do
       {:ok, params, rest} -> 
          case parse_block_statement(rest) do
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


  defp parse_call_expression([token | rest], function) do
    if token.type != :lparen do
      {:error, ["expected '(' to start call expression got '#{token.literal}'"], rest}
    else
      case parse_call_arguments(rest) do
        {:ok, args, rest} -> {:ok, %CallExpression{token: token, function: function, arguments: args}, rest}
        {:error, errors, rest} -> {:error, errors, rest}
      end
    end
  end

  defp parse_call_arguments(a, acc \\ [], end_token \\ :rparen)
  defp parse_call_arguments([token | tokens], acc, end_token) do
    case token.type do
       ^end_token -> {:ok, Enum.reverse(acc), tokens}
      :comma -> parse_call_arguments(tokens, acc, end_token)
      _ -> 
        case parse_expression([token | tokens], :lowest) do
          {:ok, expr, tokens} -> 
            parse_call_arguments(tokens, [expr | acc], end_token)
          {:error, errors, tail} -> {:error, errors, tail}
        end
    end
  end
  defp parse_call_arguments([], _, _), do: {:error, ["could not parse call arguments for call expression"], []}

  defp parse_string_literal([%Token{type: :string} = token | tail]) do
    {:ok, %StringLiteral{token: token, value: token.literal}, tail}
  end

  defp parse_array_literal(tokens) do
    case parse_call_arguments(tokens, [], :rbracket) do
      {:ok, elements, tokens} -> {:ok, %Parser.ArrayLiteral{elements: elements}, tokens}
    end
  end

  defp parse_prefix([%Token{type: :bang} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :minus} | _] = tokens), do: parse_prefix_expression(tokens)
  defp parse_prefix([%Token{type: :lparen} | _] = tokens), do: parse_grouped_expression(tokens)
  defp parse_prefix([%Token{type: :int} | _] = tokens), do: parse_integer_literal(tokens)
  defp parse_prefix([%Token{type: :ident} | _] = tokens), do: parse_identifier(tokens)
  defp parse_prefix([%Token{type: :true} | _] = tokens), do: parse_boolean(tokens)
  defp parse_prefix([%Token{type: :false} | _] = tokens), do: parse_boolean(tokens)
  defp parse_prefix([%Token{type: :if} | _] = tokens), do: parse_if_expression(tokens)
  defp parse_prefix([%Token{type: :lbracket} | tail]), do: parse_array_literal(tail)
  defp parse_prefix([%Token{type: :function} | tail]), do: parse_function_literal(tail)
  defp parse_prefix([%Token{type: :string} | _] = tokens), do: parse_string_literal(tokens)
  defp parse_prefix([%Token{type: :lbrace} | tail]), do: {:error, ["found '{' without a function or if expression to start"], tail}
  defp parse_prefix([%Token{type: :rbrace} | tail]), do: {:error, ["found '}' without a block to close"], tail}
  defp parse_prefix([%Token{type: :else} | tail]), do: {:error, ["found else keyword with no prior if block"], tail}
  defp parse_prefix([%Token{type: :assign} | tail]), do: {:error, ["assignment '=' without let statement is not allowed"], tail}
  defp parse_prefix([%Token{literal: literal, type: type} | tail]), do: {:error, ["no prefix parse function for #{String.upcase(Atom.to_string(type))}: #{literal}"], tail}

  defp parse_infix_expression(node, [], _), do: {:ok, node, []}
  defp parse_infix_expression(left, [%Token{} = token | tail] = rest, precedence) do
    current_precedence = precedence_of(token)

    if current_precedence > precedence and infix_operator?(token) and token.type != :semicolon do
      case token.type do
        :lparen -> case parse_call_expression([token | tail], left) do
          {:ok, call, tail} -> parse_infix_expression(call, tail, precedence)
          {:error, errors, rest} -> {:error, errors, rest}
        end
        :lbracket -> case parse_index_expression([token | tail], left) do
          {:ok, index, tail} -> parse_infix_expression(index, tail, precedence)
          {:error, errors, rest} -> {:error, errors, rest}
        end
          _ -> case parse_expression(tail, decode(current_precedence)) do
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

  defp parse_index_expression([token | tail], left) do
    case parse_expression(tail, :lowest) do
      {:ok, val, [%Token{type: :rbracket} | tail]} -> {:ok, %IndexExpression{token: token, left: left, index: val}, tail}
      {:error, errors, rest} -> {:error, errors, rest}
    end
    
  end

  defp parse_expression(tokens, precedence \\ :_) do
    case parse_prefix(tokens) do
      {:ok, left, rest} -> parse_infix_expression(left, rest, encode(precedence))
      {:error, errors, rest} -> 
        {:error, errors, rest}
    end
  end

  defp infix_operator?(%Token{type: t}) do
    t in [:plus, :minus, :asterix, :slash, :gt, :lt, :eq, :not_eq, :lparen, :lbracket]
  end
end
