defmodule Evaluator.Integer do
  defstruct value: 0

  defimpl Evaluator.Object, for: Evaluator.Integer do
    def type(_) do
      "INTEGER"
    end
  end

  defimpl String.Chars, for: Evaluator.Integer do
    def to_string(%Evaluator.Integer{} = int) do
      "#{int.value}"
    end
  end
end
