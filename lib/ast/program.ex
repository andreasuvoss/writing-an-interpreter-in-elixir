defmodule AST.Program do
  defstruct statements: []

  defimpl String.Chars, for: AST.Program do
    def to_string(%AST.Program{} = program) do
      program.statements |> Enum.map(fn s -> "#{s}" end) |> Enum.join("")
    end
  end
end
