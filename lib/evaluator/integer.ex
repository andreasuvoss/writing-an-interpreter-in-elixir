defmodule Evaluator.Integer do
  defstruct value: 0

  defimpl Evaluator.Object, for: Evaluator.Integer do
    def inspect(object) do
      IO.puts(object.value)
    end
  end
end
