defmodule Trex.Mixfile do
  use Mix.Project

  def project do
    [ app: :trex,
      version: "0.0.1",
      elixir: "~> 0.12.0",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:httpotion]]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
      { :httprot, github: "meh/httprot" }
    ]
  end
end
