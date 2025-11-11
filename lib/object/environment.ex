defmodule Object.Environment do
  defstruct store: %{}, outer: nil

  def create_enclosed_environment(%Object.Environment{} = outer) do
    %Object.Environment{store: %{}, outer: outer}
  end

  def set(%Object.Environment{store: store, outer: outer}, name, val) do
    %Object.Environment{store: Map.put(store, name, val), outer: outer}
  end

  def get(%Object.Environment{store: store, outer: outer}, name) do
    case {store |> Map.get(name), outer} do
      {nil, nil} -> {:error, "identifier not found: #{name}"}
      {nil, outer} -> Object.Environment.get(outer, name)
      {val, _} -> {:ok, val}
    end
    
  end
end
