defmodule Tr.MixProject do
  use Mix.Project

  def project do
    [
      app: :tr,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:castore, "~> 0.1.0"},
      {:mint, "~> 1.0"}
    ]
  end
end
