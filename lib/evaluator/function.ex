defmodule Evaluator.Function do
  alias Evaluator.Environment
  defstruct parameters: [], body: %Parser.BlockStatement{}, env: %Environment{}, name: nil

  defimpl Evaluator.Object, for: Evaluator.Function do
    def type(_) do
      "FUNCTION"
    end

    def inspect(function) do
      params = function.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      IO.puts("fn(#{params}){\n #{function.body} \n}")
    end
  end

end
