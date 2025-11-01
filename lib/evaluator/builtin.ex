defmodule Evaluator.Builtin do
  defstruct fn: nil

  defimpl Evaluator.Object, for: Evaluator.Builtin do
    def type(_) do
      "BUILTIN"
    end
  end

  defimpl String.Chars, for: Evaluator.Builtin do
    def to_string(%Evaluator.Builtin{}) do
      "builtin function"
    end
  end
end
