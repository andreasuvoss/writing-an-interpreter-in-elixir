defmodule Evaluator.Array do
  defstruct elements: [] 

  defimpl Evaluator.Object, for: Evaluator.Array do
    def type(_) do
      "ARRAY"
    end
  end

  defimpl String.Chars, for: Evaluator.Array do
    def to_string(%Evaluator.Array{} = array) do
      elements = array.elements|> Enum.map(fn e -> "#{e}" end) |> Enum.join(", ")
      "[#{elements}]"
    end
  end
end
