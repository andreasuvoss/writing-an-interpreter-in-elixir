defmodule Object.Boolean do
  defstruct value: false

  defimpl Object.Object, for: Object.Boolean do
    def type(_) do
      "BOOLEAN"
    end
  end

  defimpl String.Chars, for: Object.Boolean do
    def to_string(%Object.Boolean{} = bool) do
      case bool.value do
        true -> "true"
        false -> "false"
      end
    end
  end
end
