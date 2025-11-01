defmodule Evaluator.Boolean do
  defstruct value: false

  defimpl Evaluator.Object, for: Evaluator.Boolean do
    def type(_) do
      "BOOLEAN"
    end
  end

  defimpl String.Chars, for: Evaluator.Boolean do
    def to_string(%Evaluator.Boolean{} = bool) do
      case bool.value do
        true -> "true"
        false -> "false"
      end
    end
  end
end
