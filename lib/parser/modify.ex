defmodule Parser.Modify do
  def modify(%Parser.Program{} = node, modifier) do
    statements = Enum.map(node.statements, fn x -> modify(x, modifier) end)
    %{node | statements: statements}
  end

  def modify(%Parser.ExpressionStatement{} = node, modifier) do
    %{node | expression: modify(node.expression, modifier)}
  end

  def modify(%Parser.InfixExpression{} = node, modifier) do
    %{node | left: modify(node.left, modifier), right: modify(node.right, modifier)}
  end

  def modify(%Parser.PrefixExpression{} = node, modifier) do
    %{node | right: modify(node.right, modifier)}
  end

  def modify(%Parser.IndexExpression{} = node, modifier) do
    %{node | left: modify(node.left, modifier), index: modify(node.index, modifier)}
  end

  def modify(%Parser.BlockStatement{} = node, modifier) do
    statements = Enum.map(node.statements, fn x -> modify(x, modifier) end)
    %{node | statements: statements}
  end

  def modify(%Parser.IfExpression{alternative: nil} = node, modifier) do
    %{node | condition: modify(node.condition, modifier), consequence: modify(node.consequence, modifier)}
  end

  def modify(%Parser.IfExpression{} = node, modifier) do
    %{node | condition: modify(node.condition, modifier), consequence: modify(node.consequence, modifier), alternative: modify(node.alternative, modifier)}
  end

  def modify(%Parser.ReturnStatement{} = node, modifier) do
    %{node | return_value: modify(node.return_value, modifier)}
  end

  def modify(%Parser.LetStatement{} = node, modifier) do
    %{node | value: modify(node.value, modifier)}
  end

  def modify(%Parser.FunctionLiteral{} = node, modifier) do
    parameters = Enum.map(node.parameters, fn p -> modify(p, modifier) end)
    %{node | body: modify(node.body, modifier), parameters: parameters}
  end

  def modify(%Parser.ArrayLiteral{} = node, modifier) do
    elements = Enum.map(node.elements, fn e -> modify(e, modifier) end)
    %{node | elements: elements}
  end

  def modify(%Parser.HashLiteral{} = node, modifier) do
    pairs = Map.new(node.pairs, fn {k, v} -> {modify(k, modifier), modify(v, modifier)} end)
    %{node | pairs: pairs}
  end


  def modify(node, modifier) do
    modifier.(node)
  end
end
