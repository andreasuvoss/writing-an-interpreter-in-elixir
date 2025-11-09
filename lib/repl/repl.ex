defmodule Repl.Repl do
  alias Evaluator.Environment
  # TODO: Maybe try to get command history: https://elixirforum.com/t/command-history-on-custom-cli-not-working-with-otp-26-but-was-with-otp-25/65702
  def loop(%Environment{} = env, %Environment{} = macro_env) do
    IO.write(">> ")
    input = IO.read(:line)
    case input do
      ":q\n" -> nil
      ":env\n" -> 
        IO.inspect(env)
        loop(env, macro_env)
      ":macro_env\n" -> 
        IO.inspect(env)
        loop(env, macro_env)
      ":memory\n" -> 
        case :erlang.process_info(self(), :memory) do
          {:memory, memory} -> IO.puts("Current memory usage: #{round(memory / 1024)}kB")
        end
        loop(env, macro_env)
      ":gc\n" -> 
        IO.puts("Forcing Erlang GC")
        :erlang.garbage_collect(self())
        loop(env, macro_env)
      _ ->
        tokens = Lexer.Lexer.tokenize(String.trim(input))
        case Parser.Parser.parse_program(tokens) do
          {:ok, program} -> 
            case Evaluator.define_macros(program, macro_env) do
              {:ok, program, macro_env} -> 
                # expanded = Evaluator.expand_macros(program, macro_env)
                case Evaluator.expand_macros(program, macro_env) do
                  {:error, error} -> IO.puts(IO.ANSI.red() <> error.message <> IO.ANSI.reset())
                    loop(env, macro_env)
                  {:ok, expanded} -> 
                    # IO.inspect(expanded)
                    case Evaluator.eval(expanded, env) do
                    {:ok, evaluated, env} -> IO.puts(evaluated)
                      loop(env, macro_env)
                    {:error, error} -> IO.puts(IO.ANSI.red() <> error.message <> IO.ANSI.reset())
                      loop(env, macro_env)
                  end
                end
            end
          {:error, errors} -> 
            IO.puts(monkey_faces())
            IO.puts("Woops! We ran into some monkey business here!")
            IO.puts("parser errors:")
            errors |> Enum.with_index(1) |> Enum.each(fn {line, index} -> IO.puts("\t#{index}. #{line}") end)
            loop(env, macro_env)
        end
    end
  end

# let unless = macro(condition, consequence, alternative) { quote(if (!(unquote(condition))) { unquote(consequence); } else { unquote(alternative); }); }
# unless(10 > 5, puts("not greater"), puts("greater"));


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
    loop(%Environment{}, %Environment{})
  end
end
