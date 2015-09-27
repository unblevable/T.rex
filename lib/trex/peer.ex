defmodule Trex.Peer do
  @moduledoc """
  Peer communication.
  """

  @doc """
  """
  def connect(state) do
    state
    |> process
    |> handshake
  end

  def process(%{"failure reason": reason}) do
    IO.inspect reason
    # System.halt(1)
  end

  def process({response, {info_hash, peer_id}}) do
    %{
      interval: interval,
      # "tracker id": tracker_id,
      # complete: seeders,
      # incomplete: leechers,
      peers: peers
    } = response

    peer = get_peer(peers, [])
    |> Enum.at(0)

    {ip, port} = peer
    {:ok, socket} = :gen_tcp.connect({96, 126, 104, 219}, 54308, [:binary, active: :once], 3_000)
    # :inet.setopts(socket, [active: n])

    # create handshake
    pstr = "BitTorrent protocol"
    pstrlen = pstr |> String.length |> Integer.to_string
    handshake = pstrlen <> pstr <> <<0, 0, 0, 0, 0, 0, 0, 0>> <> info_hash <> peer_id
    # handshake_message = to_string([
    #   19,
    #   "BitTorrent protocol",
    #   <<0, 0, 0, 0, 0, 0, 0, 0>>,
    #   info_hash,
    #   "-AZ4004-znmphhbrij37"
    # ])

    :gen_tcp.send(socket, handshake)

    receive do
      {:tcp, socket, data} ->
        {socket, data}
      {:tcp_closed, socket} ->
        {ip, port, "Closed."}
      {:tcp_error, socket, reason} ->
        reason
      _ -> IO.puts "What?"
    after
      3_000 ->
        IO.puts "Timeout!"
    end
    # <<
    #   pstrlen::size(8),
    #   pstr::binary-size(19),
    #   reserved::binary-size(8),
    #   _::binary
    # >> = "19" <> "BitTorrent protocol" <> <<0, 0, 0, 0, 0, 0, 0, 0>> <>
    # # TODO: change into a record?
    # state = %{
    #   # peer is choking client
    #   is_choked: 1,
    #   # client is choking peer
    #   is_choking: 1,
    # }
  end

  # peers is a binary string consisting of 6 bytes for each peer. first 4
  # bytes are each octet the peer's ip address, last 2 bytes are for the port
  # number (big endian which is implied)
  def get_peer(<<a::integer-size(8), b::integer-size(8), c::integer-size(8), d::integer-size(8)>> <> <<port::integer-size(16), rest::binary>>, acc) do
    ipv4 = {a, b, c, d}
    get_peer(rest, [{ipv4, port} | acc])
  end

  def get_peer(_, acc) do
    acc
  end

  def handshake(peer) do
    peer
  end
end
