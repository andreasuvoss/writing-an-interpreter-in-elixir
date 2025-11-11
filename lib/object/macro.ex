defmodule Object.Macro do
  alias Object.Environment
  defstruct parameters: [], body: %AST.BlockStatement{}, env: %Environment{}

  defimpl Object.Object, for: Object.Macro do
    def type(_) do
      "MACRO"
    end
  end

  defimpl String.Chars, for: Object.Macro do
    def to_string(%Object.Macro{} = function) do
      params = function.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      "macro(#{params}){\n #{function.body} \n}"
    end
  end

end
