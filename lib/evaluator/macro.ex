defmodule Evaluator.Macro do
  alias Evaluator.Environment
  defstruct parameters: [], body: %Parser.BlockStatement{}, env: %Environment{}

  defimpl Evaluator.Object, for: Evaluator.Macro do
    def type(_) do
      "MACRO"
    end
  end

  defimpl String.Chars, for: Evaluator.Macro do
    def to_string(%Evaluator.Macro{} = function) do
      params = function.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      "macro(#{params}){\n #{function.body} \n}"
    end
  end

end
