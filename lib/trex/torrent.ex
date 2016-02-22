defmodule Trex.Torrent do
  @moduledoc """
  Manage torrent lifespan.
  """

  use GenServer

  alias Trex.Bencode
  alias Trex.Protocol
  alias Trex.Swarm
  alias Trex.Tracker

  @timeout 5_000

  # Client -------------------------------------------------------------------

  @doc false
  def start_link(lsocket, binary) do
    GenServer.start_link(__MODULE__, [lsocket, binary], timeout: @timeout)
  end

  # Server -------------------------------------------------------------------

  def init([lsocket, binary]) do
    # TODO: optional keys
    # TODO: multiple-file torrents
    # NOTE: should this be init?
    %{
      announce: _announce,
      info: info = %{
        "piece length": _piece_length,
        pieces: _pieces,
        name: _name,
        length: length
      }
    } = file_info =
      Bencode.decode(binary)

    info_hash =
      :crypto.hash(:sha, Bencode.encode(info))

    client_id =
      Application.get_env(:trex, :client_id)

    # TODO: optional keys
    # TODO: BEP 23
    request_params = %{
      compact: 1,
      downloaded: 0,
      event: "started",
      info_hash: info_hash,
      # ip: "127.0.0.1",
      left: length,
      # TODO: move elsewhere
      peer_id: client_id,
      port: Application.get_env(:trex, :port),
      uploaded: 0
    }

    request_url =
      file_info.announce <> "?" <> URI.encode_query(request_params)

    # TODO: timeout or error handling
    %{
      interval: _interval,
      peers: peers_binary
    } = tracker_info = Tracker.request(request_url)

    state = %{
      file_info: file_info,
      swarm: start_swarm(lsocket, peers_binary, info_hash, client_id),
      tracker_info: tracker_info,
    }

    {:ok, state}
  end

  # Helpers ------------------------------------------------------------------

  defp start_swarm(lsocket, peers_binary, info_hash, client_id) do
    {:ok, swarm} = Supervisor.start_link(Trex.Swarm, [])

    handshake_msg =
      Protocol.encode(:handshake, <<0::size(64)>>, info_hash, client_id)

    # NOTE: use proc_lib?
    # Call spawn_link() to prevent a deadlock in init(), since each peer will
    # block to wait for messages.
    spawn_link(fn ->
      start_peers(swarm, lsocket, peers_binary, handshake_msg)
    end)

    swarm
  end

  defp start_peers(swarm, lsocket, peers_binary, handshake_msg) do
    peers_binary
    |> parse_peers_binary
    |> Enum.take_random(Application.get_env(:trex, :num_peers))
    |> Enum.map(fn {ip, port} ->
      Swarm.start_peer(swarm, ip, port, lsocket, handshake_msg)
    end)
  end

  # The binary contains a series of 6 bytes per peer.
  #
  # Each of the first 4 bytes hold an octet of the peer's ip address. The last
  # 2 bytes hold the peer's port number.
  defp parse_peers_binary(binary) do
    parse_peers_binary(binary, [])
  end

  defp parse_peers_binary(<<a, b, c, d, port::size(16), rest::bytes>>, acc) do
    parse_peers_binary(rest, [{{a, b, c, d}, port} | acc])
  end

  defp parse_peers_binary(_, acc) do
    acc
  end
end
