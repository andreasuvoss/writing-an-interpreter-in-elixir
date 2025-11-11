defmodule Parser.Modify do
  def modify(%AST.Program{} = node, modifier) do
    case traverse_nodes(node.statements, fn x -> modify(x, modifier) end) do
      {:ok, stmts} -> {:ok, %{node | statements: stmts}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.ExpressionStatement{} = node, modifier) do
    case modify(node.expression, modifier) do
      {:ok, expr} -> {:ok, %{node | expression: expr}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.InfixExpression{} = node, modifier) do
    with {:ok, left} <- modify(node.left, modifier),
         {:ok, right} <- modify(node.right, modifier) do
      {:ok, %{node | left: left, right: right}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.PrefixExpression{} = node, modifier) do
    case modify(node.right, modifier) do
      {:ok, right} -> {:ok, %{node | right: right}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.IndexExpression{} = node, modifier) do
    with {:ok, left} <- modify(node.left, modifier),
         {:ok, index} <- modify(node.index, modifier) do
      {:ok, %{node | left: left, index: index}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.BlockStatement{} = node, modifier) do
    case traverse_nodes(node.statements, fn x -> modify(x, modifier) end) do
      {:ok, stmts} -> 
        {:ok, %{node | statements: stmts}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.IfExpression{alternative: nil} = node, modifier) do
    with {:ok, condition} <- modify(node.condition, modifier),
         {:ok, consequence} <- modify(node.consequence, modifier) do
      {:ok, %{node | condition: condition, consequence: consequence}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.IfExpression{} = node, modifier) do
    with {:ok, condition} <- modify(node.condition, modifier),
         {:ok, consequence} <- modify(node.consequence, modifier),
         {:ok, alternative} <- modify(node.alternative, modifier) do
      {:ok, %{node | condition: condition, consequence: consequence, alternative: alternative}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.ReturnStatement{} = node, modifier) do
    case modify(node.return_value, modifier) do
      {:ok, return_value} -> {:ok, %{node | return_value: return_value}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.LetStatement{} = node, modifier) do
    case modify(node.value, modifier) do
      {:ok, value} -> {:ok, %{node | value: value}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.FunctionLiteral{} = node, modifier) do
    with {:ok, parameters} <- traverse_nodes(node.parameters, fn x -> modify(x, modifier) end),
         {:ok, body} <- modify(node.body, modifier) do
      {:ok, %{node | body: body, parameters: parameters}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.ArrayLiteral{} = node, modifier) do
    case traverse_nodes(node.elements, fn x -> modify(x, modifier) end) do
      {:ok, elements} -> {:ok, %{node | elements: elements}}
      {:error, error} -> {:error, error}
    end
  end

  def modify(%AST.HashLiteral{} = node, modifier) do
    case traverse_map(node.pairs, &modify(&1, modifier)) do
      {:ok, pairs} -> {:ok, %{node | pairs: pairs}}
      {:error, _} = error -> error
    end
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
