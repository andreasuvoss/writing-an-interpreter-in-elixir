defmodule Evaluator.String do
  defstruct value: ""

  defimpl Evaluator.Object, for: Evaluator.String do
    def type(_) do
      "STRING"
    end
  end

  defimpl String.Chars, for: Evaluator.String do
    def to_string(%Evaluator.String{} = string) do
      "\"#{string.value}\""
    end
  end
end
