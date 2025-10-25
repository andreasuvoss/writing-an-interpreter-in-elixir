defmodule Repl.Repl do
  alias Evaluator.Environment
  # TODO: Maybe try to get command history: https://elixirforum.com/t/command-history-on-custom-cli-not-working-with-otp-26-but-was-with-otp-25/65702
  def loop(%Environment{} = env) do
    # IO.inspect(env)
    IO.write(">> ")
    input = IO.read(:line)
    case input do
      ":q\n" -> nil
      ":env\n" -> IO.inspect(env)
        loop(env)
      _ ->
        tokens = Lexer.Lexer.tokenize(String.trim(input))
        case Parser.Parser.parse_program(tokens) do
          {:ok, program} -> 
            case Evaluator.Evaluator.eval(program, env) do
              {:ok, evaluated, env} -> Evaluator.Object.inspect(evaluated)
                loop(env)
              {:error, error} -> IO.puts(IO.ANSI.red() <> error.message <> IO.ANSI.reset())
                loop(env)
            end
            # IO.puts(program)
            # IO.inspect(program)
          {:error, errors} -> 
            IO.puts(monkey_faces())
            IO.puts("Woops! We ran into some monkey business here!")
            IO.puts("parser errors:")
            errors |> Enum.with_index(1) |> Enum.each(fn {line, index} -> IO.puts("\t#{index}. #{line}") end)
            loop(env)
        end
        # loop(env)
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
    loop(%Environment{})
  end
end
