defmodule Object.Function do
  alias Object.Environment
  defstruct parameters: [], body: %AST.BlockStatement{}, env: %Environment{}, name: nil

  defimpl Object.Object, for: Object.Function do
    def type(_) do
      "FUNCTION"
    end
  end

  defimpl String.Chars, for: Object.Function do
    def to_string(%Object.Function{} = function) do
      params = function.parameters |> Enum.map(fn p -> "#{p}" end) |> Enum.join(", ")
      "fn(#{params}){\n #{function.body} \n}"
    end
  end

end
