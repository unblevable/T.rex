defmodule Trex.Mixfile do
  use Mix.Project

  @port 6881
  @version "0.0.1"

  def project do
    [
      app: :trex,
      version: @version,
      elixir: "~> 1.1.1",
      escript: [main_module: Trex.Cli, path: "bin/trex"],
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
      applications: [:crypto, :httpoison, :logger],
      env: [
        # unique peer id for currently running client
        client_id: generate_client_id,

        # port number to bind to
        port: @port,

        # initial number of peers to connect to
        num_peers: 2
      ],
      mod: {Trex, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~>0.7.3"}
    ]
  end

  # Helpers ------------------------------------------------------------------

  # Generate a peer id for the currently running client.
  #
  # Follow an "Azureus-style"-inspired convention for a unique peer id that
  # is exactly 20 bytes long.
  #
  # -RX0.0.1-cf23df2207d9e
  #  ^ ^     ^
  #
  # + T.rex's client abbreviation
  #
  # + Version number
  #   This will be variable length.
  #
  # + Hash
  #   This should fill the remaining bytes in the peer id. It is meant to be
  #   unique and random. The hash will be generated from a part of a SHA1
  #   hash of the running process id (which should be unique enough).

  @client_abbr "RX"
  @peer_id_length 20

  defp generate_client_id do
    hash_length =
      @peer_id_length - (
        1 +
        byte_size(@client_abbr) +
        1 +
        byte_size(@version)
      )

    hash =
      :crypto.rand_bytes(hash_length)

    "-" <> @client_abbr <> @version <> "-" <> hash
  end
end
