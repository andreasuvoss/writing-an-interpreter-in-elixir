defmodule Object.Array do
  defstruct elements: [] 

  defimpl Object.Object, for: Object.Array do
    def type(_) do
      "ARRAY"
    end
  end

  defimpl String.Chars, for: Object.Array do
    def to_string(%Object.Array{} = array) do
      elements = array.elements|> Enum.map(fn e -> "#{e}" end) |> Enum.join(", ")
      "[#{elements}]"
    end
  end
end
