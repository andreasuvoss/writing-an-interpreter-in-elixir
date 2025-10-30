defmodule Evaluator.Builtin do
  defstruct fn: nil

  defimpl Evaluator.Object, for: Evaluator.Builtin do
    def type(_) do
      "BUILTIN"
    end

    def inspect(_) do
      # IO.puts(object.value)
    end
  end
end
