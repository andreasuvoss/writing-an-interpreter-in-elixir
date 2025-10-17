defmodule Repl.Repl do
  # TODO: Maybe try to get command history: https://elixirforum.com/t/command-history-on-custom-cli-not-working-with-otp-26-but-was-with-otp-25/65702
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
