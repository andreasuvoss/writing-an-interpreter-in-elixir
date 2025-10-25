defmodule Evaluator.Environment do
  defstruct store: %{}, outer: nil

  def create_enclosed_environment(%Evaluator.Environment{} = outer) do
    %Evaluator.Environment{store: %{}, outer: outer}
  end

  def set(%Evaluator.Environment{store: store, outer: outer}, name, val) do
    %Evaluator.Environment{store: Map.put(store, name, val), outer: outer}
  end

  def get(%Evaluator.Environment{store: store, outer: outer}, name) do
    # IO.inspect(env)
    case {store |> Map.get(name), outer} do
      {nil, nil} -> {:error, "identifier not found: #{name}"}
      {nil, outer} -> Evaluator.Environment.get(outer, name)
      {val, _} -> {:ok, val}
    end
    
  end
end
