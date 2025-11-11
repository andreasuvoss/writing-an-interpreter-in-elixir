defmodule Object.Null do
  defstruct [] 

  defimpl Object.Object, for: Object.Null do
    def type(_) do
      "NULL"
    end
  end

  defimpl String.Chars, for: Object.Null do
    def to_string(%Object.Null{}) do
      "null"
    end
  end
end
