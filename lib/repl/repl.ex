defmodule Repl.Repl do
  # TODO: Maybe try to get command history: https://elixirforum.com/t/command-history-on-custom-cli-not-working-with-otp-26-but-was-with-otp-25/65702
  def loop() do
    IO.write(">> ")
    input = IO.read(:line)
    case input do
      ":q\n" -> nil
      _ ->
        tokens = Lexer.Lexer.tokenize(String.trim(input))
        program = Parser.Parser.parse_program(tokens)
        IO.puts(program)
        loop()
    end
  end

  def start() do
    loop()
  end
end
