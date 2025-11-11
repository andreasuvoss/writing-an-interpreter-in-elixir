defmodule Object.Quote do
  defstruct node: %{}

  defimpl Object.Object, for: Object.Quote do
    def type(_) do
      "QUOTE"
    end
  end

  defimpl String.Chars, for: Object.Quote do
    def to_string(%Object.Quote{} = quote) do
      "QUOTE(#{quote.node})"
    end
  end
end
