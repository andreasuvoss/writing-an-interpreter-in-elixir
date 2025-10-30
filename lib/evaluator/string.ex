defmodule Evaluator.String do
  defstruct value: ""

  defimpl Evaluator.Object, for: Evaluator.String do
    def type(_) do
      "STRING"
    end

    def inspect(object) do
      IO.puts("\"#{object.value}\"")
    end
  end
end
