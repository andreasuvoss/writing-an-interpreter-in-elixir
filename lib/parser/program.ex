defmodule Parser.Program do
  defstruct statements: []

  defimpl String.Chars, for: Parser.Program do
    def to_string(%Parser.Program{} = program) do
      program.statements |> Enum.map(fn s -> Parser.Statement.string(s) end) |> Enum.join("\n")
    end
  end
end
