defmodule Repl.Repl do
  def loop() do
    IO.write(">> ")
    input = IO.read(:line)
    case input do
      ":q\n" -> nil
      _ -> 
        tokens = Lexer.Lexer.tokenize(String.trim(input))
        tokens |> Enum.each(fn x -> IO.inspect(x) end)
        loop()
    end
  end

  def start() do
    loop()
  end
end
