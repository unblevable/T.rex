defmodule Trex.Tracker do
  @moduledoc"""
  Make a request to a tracker and handle its responses.
  """

  alias Trex.Bencode
  alias Trex.Peer
  require Logger

  @version Mix.Project.config[:version]
  @client_id "RX"
  @peer_id_length 20
  @client_id_and_hyphens_length 4

  @tracker_defaults %{
    port: 6881
  }

  @doc """
  Creates and sends a GET request to the tracker and returns its response.
  """
  def request(binary) do
    {announce, request_params} =
      binary
      |> Bencode.decode
      |> get_request_params

    %{
      info_hash: info_hash,
      peer_id: peer_id
    } = request_params

    peers =
      announce <> "?" <> URI.encode_query(request_params)
      |> send_request
      |> Bencode.decode
      |> handle_response

    {peers, info_hash, peer_id}
  end

  defp get_request_params(metainfo) do
    # TODO: optional keys
    # TODO: multiple-file torrents
    %{
      announce: announce,
      info: info = %{
        "piece length": _piece_length,
        pieces: _pieces,
        name: _name,
        length: length
      }
    } = metainfo

    # Follow an "Azureus-style"-inspired convention for a unique peer id that
    # is exactly 20 bytes long.
    #
    # -RX0.0.1-cf23df2207d9e
    #  ^ ^     ^
    #
    # + T.rex's client id
    #
    # + Version number
    #   This will be variable length.
    #
    # + Hash
    #   This should fill the remaining bytes in the peer id. It is meant to be
    #   unique and random. The hash will be generated from a part of a SHA1
    #   hash of the running process id (which should be unique enough).

    hash_length = @peer_id_length - (@client_id_and_hyphens_length + byte_size(@version))
    hash        = :crypto.rand_bytes(hash_length)
    peer_id     = "-" <> @client_id <> @version <> "-" <> hash

    info_hash = :crypto.hash(:sha, Bencode.encode(info))

    # TODO: optional keys
    # TODO: BEP 23
    request_params = %{
      info_hash: info_hash,
      peer_id: peer_id,
      # "ip" => "127.0.0.1",
      port:  @tracker_defaults[:port],
      uploaded: 0,
      downloaded: 0,
      left: length,
      event: "started",
      compact: 1
    }

    {announce, request_params}
  end

  # TODO: better error handling
  defp send_request(uri) do
    case HTTPoison.get(uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.info 404
        # System.halt(1)
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        # System.halt(1)
    end
  end

  defp handle_response(response) do
    %{
      interval: _interval,
      # "tracker id": tracker_id,
      # complete: seeders,
      # incomplete: leechers,
      peers: peers_binary
    } = response
    peers_binary
  end
end
