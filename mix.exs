defmodule Trex.Mixfile do
  use Mix.Project

  def project do
    [ app: :trex,
      escript: [main_module: Trex],
      version: "0.0.1",
      elixir: "~> 1.0.0",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:hackney]]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
      # { :httprot, github: "meh/httprot" },
      { :hackney, github: "benoitc/hackney" }
    ]
  end
end
