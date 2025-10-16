defmodule Parser.Program do
  defstruct statements: []

  defimpl String.Chars, for: Parser.Program do
    def to_string(%Parser.Program{} = program) do
      program.statements |> Enum.map(fn s -> "#{s}" end) |> Enum.join("")
    end
  end
end
