defmodule Object.Hash do
  defstruct pairs: [] 

  defimpl Object.Object, for: Object.Hash do
    def type(_) do
      "ARRAY"
    end
  end

  defimpl String.Chars, for: Object.Hash do
    def to_string(%Object.Hash{} = hash) do
      pairs = hash.pairs |> Enum.map(fn {k, v} -> "#{k}: #{v}" end) |> Enum.join(", ")
      "{#{pairs}}"
    end
  end
end
