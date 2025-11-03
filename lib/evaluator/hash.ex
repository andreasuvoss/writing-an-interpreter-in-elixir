defmodule Evaluator.Hash do
  defstruct pairs: [] 

  defimpl Evaluator.Object, for: Evaluator.Hash do
    def type(_) do
      "ARRAY"
    end
  end

  defimpl String.Chars, for: Evaluator.Hash do
    def to_string(%Evaluator.Hash{} = hash) do
      pairs = hash.pairs |> Enum.map(fn {k, v} -> "#{k}: #{v}" end) |> Enum.join(", ")
      "{#{pairs}}"
    end
  end
end
