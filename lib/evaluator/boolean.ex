defmodule Evaluator.Boolean do
  defstruct value: false

  defimpl Evaluator.Object, for: Evaluator.Boolean do
    def inspect(object) do
      IO.puts(object.value)
    end
  end
end
