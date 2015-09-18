defmodule Trex.Tracker do
  @moduledoc"""
  Tracker requests/responses.
  """

  alias Trex.Bencode

  @peer_id_length 20
  @client_id_and_hyphens_length 4
  @version Mix.Project.config[:version]

  @tracker_defaults %{
    port: 6881
  }

  @doc """
  Creates and sends a GET request to the tracker and returns its response.
  """
  def request(binary) do
    binary
    |> Bencode.decode
    |> create_request
    |> send_request
    |> Bencode.decode
  end

  defp create_request(metainfo) do
    # TODO: optional keys
    # TODO: multiple-file torrents
    %{
      announce: announce,
      info: info = %{
        "piece length": piece_length,
        pieces: pieces,
        name: name,
        length: length
      }
    } = metainfo

    # Follow an "Azureus-style"-inspired convention for a unique peer id that
    # is exactly 20 bytes long.
    #
    # -RX0.0.1-cf23df2207d9e
    #  ^ ^     ^
    #
    # * T.rex's client id
    #
    # * Version number
    #   This will be variable length.
    #
    # * Hash
    #   This should fill the remaining bytes in the peer id. It is meant to be
    #   unique and random. The hash will be generated from a part of a SHA1
    #   hash of the running process id (which should be unique enough).

    hash_length = @peer_id_length - @client_id_and_hyphens_length - byte_size(@version)
    hash        = :crypto.hash(:sha, System.get_pid) |> binary_part(0, hash_length)
    peer_id     = "-RX#{@version}-#{hash}"

    # TODO: optional keys
    # TODO: BEP 23
    request_params = %{
      info_hash: :crypto.hash(:sha, Bencode.encode(info)),
      peer_id: peer_id,
      # "ip" => "127.0.0.1",
      port:  @tracker_defaults[:port],
      uploaded: 0,
      downloaded: 0,
      completed: length,
      event: "started"
    }

    announce <> "?" <> URI.encode_query(request_params)
  end

  defp send_request(uri) do
    case HTTPoison.get(uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "404"
        # System.halt(1)
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        # System.halt(1)
    end
  end
end
