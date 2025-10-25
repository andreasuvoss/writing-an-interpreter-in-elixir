defmodule Evaluator.Boolean do
  defstruct value: false

  defimpl Evaluator.Object, for: Evaluator.Boolean do
    def type(_) do
      "BOOLEAN"
    end

    def inspect(object) do
      IO.puts(object.value)
    end
  end
end
