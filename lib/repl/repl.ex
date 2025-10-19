defmodule Repl.Repl do
  # TODO: Maybe try to get command history: https://elixirforum.com/t/command-history-on-custom-cli-not-working-with-otp-26-but-was-with-otp-25/65702
  def loop() do
    IO.write(">> ")
    input = IO.read(:line)
    case input do
      ":q\n" -> nil
      _ ->
        tokens = Lexer.Lexer.tokenize(String.trim(input))
        case Parser.Parser.parse_program(tokens) do
          {:ok, program} -> IO.puts(program)
            # IO.inspect(program)
          {:error, errors} -> 
            IO.puts(monkey_faces())
            IO.puts("Woops! We ran into some monkey business here!")
            IO.puts("parser errors:")
            errors |> Enum.with_index(1) |> Enum.each(fn {line, index} -> IO.puts("\t#{index}. #{line}") end)
        end
        loop()
    end
  end

  def monkey_faces() do
    """
         .-"-.            .-"-.            .-"-.           .-"-.
       _/_-.-_\\_        _/.-.-.\\_        _/.-.-.\\_       _/.-.-.\\_
      / __} {__ \\      /|( o o )|\\      ( ( o o ) )     ( ( o o ) )
     / //  "  \\\\ \\    | //  "  \\\\ |      |/  "  \\|       |/  "  \\|
    / / \\'---'/ \\ \\  / / \\'---'/ \\ \\      \\'/^\\'/         \\ .-. /
    \\ \\_/`"""`\\_/ /  \\ \\_/`"""`\\_/ /      /`\\ /`\\         /`"""`\\
     \\           /    \\           /      /  /|\\  \\       /       \\
    """
  end

  def start() do
    loop()
  end
end
