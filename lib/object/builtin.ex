defmodule Object.Builtin do
  defstruct fn: nil

  defimpl Object.Object, for: Object.Builtin do
    def type(_) do
      "BUILTIN"
    end
  end

  defimpl String.Chars, for: Object.Builtin do
    def to_string(%Object.Builtin{}) do
      "builtin function"
    end
  end
end
