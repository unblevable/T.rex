defmodule Trex.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :trex,
      version: @version,
      elixir: "~> 1.0.4",
      escript: [main_module: Trex],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      name: "T.rex",
      source_url: "https://github.com/unblevable/T.rex",
      description: "A BitTorrent client in Elixir."
    ]
  end

  def application do
    [applications: [:httpoison]]
  end

  defp deps do
    [{:httpoison, "~>0.7.3"}]
  end
end
