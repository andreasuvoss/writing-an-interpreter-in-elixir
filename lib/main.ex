defmodule Main do
  use Application

  def start(start_type, start_args) do
    IO.puts("hwllo")
    {:ok, self()}
  end
end
