defmodule Repl do
  # TODO: Maybe try to get command history: https://elixirforum.com/t/command-history-on-custom-cli-not-working-with-otp-26-but-was-with-otp-25/65702
  def loop(%Object.Environment{} = env, %Object.Environment{} = macro_env) do
    IO.write(">> ")
    input = IO.read(:line)
    case input do
      ":q\n" -> nil
      ":help\n" ->
        IO.puts("   :q \t\t -> quits the interpreter")
        IO.puts("   :env \t -> shows the environment used when evaluating the program")
        IO.puts("   :macro_env \t -> shows the environment used when evaluating macros")
        IO.puts("   :memory \t -> shows how much memory the interpreter is using")
        IO.puts("   :gc \t\t -> force Erlang VM garbage collection")
        IO.puts("   :help\t -> shows this message")
        loop(env, macro_env)
      ":env\n" -> 
        IO.inspect(env)
        loop(env, macro_env)
      ":macro_env\n" -> 
        IO.inspect(macro_env)
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
        tokens = Lexer.tokenize(String.trim(input))
        with {:ok, program} <- Parser.parse_program(tokens),
             {:ok, program, macro_env} <- Evaluator.define_macros(program, macro_env),
             {:ok, expanded} <- Evaluator.expand_macros(program, macro_env),
             {:ok, evaluated, env} <- Evaluator.eval(expanded, env)
        do
            IO.puts(evaluated)
            loop(env, macro_env)
        else
          {:error, [_ | _] = errors} -> 
            IO.puts(monkey_faces())
            IO.puts("Woops! We ran into some monkey business here!")
            IO.puts("parser errors:")
            errors |> Enum.with_index(1) |> Enum.each(fn {line, index} -> IO.puts("   #{index}. #{line}") end)
            loop(env, macro_env)
          {:error, error} -> IO.puts(IO.ANSI.red() <> error.message <> IO.ANSI.reset())
              loop(env, macro_env)
        end
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
    loop(%Object.Environment{}, %Object.Environment{})
  end
end
