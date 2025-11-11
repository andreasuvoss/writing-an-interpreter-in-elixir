defmodule Object.Integer do
  defstruct value: 0

  defimpl Object.Object, for: Object.Integer do
    def type(_) do
      "INTEGER"
    end
  end

  defimpl String.Chars, for: Object.Integer do
    def to_string(%Object.Integer{} = int) do
      "#{int.value}"
    end
  end
end
