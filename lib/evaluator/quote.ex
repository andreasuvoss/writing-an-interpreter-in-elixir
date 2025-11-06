defmodule Evaluator.Quote do
  defstruct node: %{}

  defimpl Evaluator.Object, for: Evaluator.Quote do
    def type(_) do
      "QUOTE"
    end
  end

  defimpl String.Chars, for: Evaluator.Quote do
    def to_string(%Evaluator.Quote{} = quote) do
      "QUOTE(#{quote.node})"
    end
  end
end
