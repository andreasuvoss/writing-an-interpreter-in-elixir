defmodule Evaluator.Null do
  defstruct [] 

  defimpl Evaluator.Object, for: Evaluator.Null do
    def type(_) do
      "NULL"
    end
  end

  defimpl String.Chars, for: Evaluator.Null do
    def to_string(%Evaluator.Null{}) do
      "null"
    end
  end
end
