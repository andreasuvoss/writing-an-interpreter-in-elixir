defmodule Evaluator.Function do
  alias Evaluator.Environment
  defstruct parameters: [], body: %Parser.BlockStatement{}, env: %Environment{}, name: nil

  defimpl Evaluator.Object, for: Evaluator.Function do
    def type(_) do
      "FUNCTION"
    end
  end

  defimpl String.Chars, for: Evaluator.Function do
    def to_string(%Evaluator.Function{} = function) do
      params = function.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      "fn(#{params}){\n #{function.body} \n}"
    end
  end

end
