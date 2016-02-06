defmodule Trex.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :trex,
      version: @version,
      elixir: "~> 1.1.1",
      escript: [main_module: Trex, path: "bin/trex"],
      # build_embedded: Mix.env == :prod,
      # start_permanent: Mix.env == :prod,
      deps: deps,
      name: "T.rex",
      source_url: "https://github.com/unblevable/T.rex",
      description: "A BitTorrent client in Elixir."
    ]
  end

  def application do
    [
      mod: {Trex, []},
      applications: [:crypto, :httpoison, :logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~>0.7.3"},
    ]
  end
end
