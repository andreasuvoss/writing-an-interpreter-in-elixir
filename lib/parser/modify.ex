defmodule Parser.Modify do

  # defp modify_nodes(nodes, mod, acc \\ [])
  #
  # defp modify_nodes([node | tail], modifier, acc) do
  #   case modify(node, modifier) do
  #     {:ok, node} -> modify_nodes(tail, modifier, [node | acc])
  #     {:error, error} -> {:error, error}
  #   end
  # end
  #
  # defp modify_nodes([], _, acc), do: {:ok, Enum.reverse(acc)}

  def modify(%Parser.Program{} = node, modifier) do
    # statements = Enum.map(node.statements, fn x -> modify(x, modifier) end)
    case traverse_nodes(node.statements, fn x -> modify(x, modifier) end) do
      {:ok, stmts} -> {:ok, %{node | statements: stmts}}
      {:error, error} -> {:error, error}
    end
    #
    # case modify_nodes(node.statements, fn x -> modify(x, modifier) end) do
    #   {:ok, stmts} -> {:ok, %{node | statements: stmts}}
    #   {:error, error} -> {:error, error}
    # end
  end

  def modify(%Parser.ExpressionStatement{} = node, modifier) do
    case modify(node.expression, modifier) do
      {:ok, expr} -> {:ok, %{node | expression: expr}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.InfixExpression{} = node, modifier) do
    with {:ok, left} <- modify(node.left, modifier),
         {:ok, right} <- modify(node.right, modifier) do
      {:ok, %{node | left: left, right: right}}
    else
      {:error, error} -> {:error, error}
    end

    # case modify(node.left, modifier) do
    #   {:error, error} -> {:error, error}
    #   left-> case modify(node.right, modifier) do
    #   {:error, error} -> {:error, error}
    #       right -> %{node | left: left, right: right}
    #   end
    # end
  end

  def modify(%Parser.PrefixExpression{} = node, modifier) do
    case modify(node.right, modifier) do
      {:ok, right} -> {:ok, %{node | right: right}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.IndexExpression{} = node, modifier) do
    with {:ok, left} <- modify(node.left, modifier),
         {:ok, index} <- modify(node.index, modifier) do
      {:ok, %{node | left: left, index: index}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.BlockStatement{} = node, modifier) do
    case traverse_nodes(node.statements, fn x -> modify(x, modifier) end) do
      {:ok, stmts} -> 
        {:ok, %{node | statements: stmts}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.IfExpression{alternative: nil} = node, modifier) do
    with {:ok, condition} <- modify(node.condition, modifier),
         {:ok, consequence} <- modify(node.consequence, modifier) do
      {:ok, %{node | condition: condition, consequence: consequence}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.IfExpression{} = node, modifier) do
    with {:ok, condition} <- modify(node.condition, modifier),
         {:ok, consequence} <- modify(node.consequence, modifier),
         {:ok, alternative} <- modify(node.alternative, modifier) do
      {:ok, %{node | condition: condition, consequence: consequence, alternative: alternative}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.ReturnStatement{} = node, modifier) do
    case modify(node.return_value, modifier) do
      {:ok, return_value} -> {:ok, %{node | return_value: return_value}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.LetStatement{} = node, modifier) do
    case modify(node.value, modifier) do
      {:ok, value} -> {:ok, %{node | value: value}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.FunctionLiteral{} = node, modifier) do
    with {:ok, parameters} <- traverse_nodes(node.parameters, fn x -> modify(x, modifier) end),
         {:ok, body} <- modify(node.body, modifier) do
      {:ok, %{node | body: body, parameters: parameters}}
    else
      {:error, error} -> {:error, error}
    end
    # case traverse_nodes(node.parameters, fn x -> modify(x, modifier) end) do
    #   {:ok, parameters} -> {:ok, %{node | parameters: parameters}}
    #   {:error, error} -> {:error, error}
    # end
  end

  def modify(%Parser.ArrayLiteral{} = node, modifier) do
    case traverse_nodes(node.elements, fn x -> modify(x, modifier) end) do
      {:ok, elements} -> {:ok, %{node | elements: elements}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%Parser.HashLiteral{} = node, modifier) do
    case traverse_map(node.pairs, &modify(&1, modifier)) do
      {:ok, pairs} -> {:ok, %{node | pairs: pairs}}
      {:error, _} = error -> error
    end
    # pairs = Map.new(node.pairs, fn {k, v} -> {modify(k, modifier), modify(v, modifier)} end)
    # %{node | pairs: pairs}
  end

  def modify(node, modifier) do
    # could rewrite this without the case, since it just returns whatever it gets
    case modifier.(node) do
      {:ok, node} -> {:ok, node}
      {:error, _} = error -> error
      res -> 
        IO.inspect(res)
        {:error, "Unknown response from modifier function. Expected either {:ok, node} or {:error, error}"}
    end
  end

  defp traverse_nodes(nodes, modifier) do
    result =
      Enum.reduce_while(nodes, [], fn node, acc ->
        case modify(node, modifier) do
          {:ok, n} -> {:cont, [n | acc]}
          {:error, _} = error -> {:halt, error}
        end
      end)


    case result do
      {:error, _} = err -> err
      acc -> {:ok, Enum.reverse(acc)}
    end
  end

  defp traverse_map(map, modifier) do
    result =
      Enum.reduce_while(map, %{}, fn {k,v}, acc ->
        with {:ok, key} <- modify(k, modifier), 
              {:ok, val} <- modify(v, modifier) do
          {:cont, Map.put(acc, key, val)}
        else
          {:error, _} = err -> {:halt, err}
        end
      end)

    case result do
      {:error, _} = err -> err
      acc -> {:ok, acc}
    end
  end
end
