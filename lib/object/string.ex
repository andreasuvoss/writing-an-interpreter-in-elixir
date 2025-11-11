defmodule Object.String do
  defstruct value: ""

  defimpl Object.Object, for: Object.String do
    def type(_) do
      "STRING"
    end
  end

  defimpl String.Chars, for: Object.String do
    def to_string(%Object.String{} = string) do
      "\"#{string.value}\""
    end
  end
end
