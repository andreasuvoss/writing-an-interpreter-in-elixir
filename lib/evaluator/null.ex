defmodule Evaluator.Null do
  defstruct [] 

  defimpl Evaluator.Object, for: Evaluator.Null do
    def type(_) do
      "NULL"
    end

    def inspect(_) do
      IO.puts("null")
    end
  end
end
