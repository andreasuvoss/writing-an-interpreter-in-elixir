defmodule Main do
  use Application

  def start(_, _) do
    {user, _} = System.cmd("whoami", [])
    user = String.trim(user)

    IO.write("Hello #{user}! This is the Monkey programming language!\n")
    IO.write("Feel free to type in commands (:q to quit or :help for help)\n\n")
    Repl.start()
    {:ok, self()}
  end
end
