defmodule Interpreter.MixProject do
  use Mix.Project

  def project do
    [
      app: :interpreter,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Main, []},
      extra_applications: [:logger]
    ]
  end

  defp deps, do: []
end
