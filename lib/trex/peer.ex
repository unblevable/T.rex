defmodule Trex.Peer do
  @moduledoc """
  Peer communication.
  """

  @timeout 2_000

  @doc """
  """
  def connect(state) do
    state
    |> process
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

    # create handshake message
    pstr = "BitTorrent protocol"
    # pstrlen = pstr |> String.length |> Integer.to_string
    pstrlen = "19"
    message = pstrlen <> pstr <> <<0, 0, 0, 0, 0, 0, 0, 0>> <> info_hash <> peer_id

    IO.inspect peer_id
    peers = parse_peers_binary(peers, [])
    handshake(peers, message)

    # {ip, port} = peer
    # {:ok, socket} = :gen_tcp.connect({96, 126, 104, 219}, 54308, [:binary, active: :once], 3_000)
    # :inet.setopts(socket, [active: n])

    # handshake_message = to_string([
    #   19,
    #   "BitTorrent protocol",
    #   <<0, 0, 0, 0, 0, 0, 0, 0>>,
    #   info_hash,
    #   "-AZ4004-znmphhbrij37"
    # ])

    # list of {ip, port}'s
    # map
    # if success continue
    # else loop

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
  def parse_peers_binary(<<a::integer-size(8), b::integer-size(8), c::integer-size(8), d::integer-size(8)>> <> <<port::integer-size(16), rest::binary>>, acc) do
    ipv4 = {a, b, c, d}
    parse_peers_binary(rest, [{ipv4, port} | acc])
  end

  def parse_peers_binary(_, acc) do
    acc
  end

  def handshake([{ip, port} | peers], message) do
    case :gen_tcp.connect(ip, port, [:binary, active: true], @timeout) do
      {:ok, socket} ->
        :gen_tcp.send(socket, message)
        receive do
          {:tcp, socket, data} ->
            {ip, port, socket, data}
          {:tcp_closed, socket} ->
            IO.puts "The socket is closed."
            IO.inspect ip
            IO.puts port
            # :inet.setopts(socket, [active: :once])
            handshake(peers, message)
          {:tcp_error, socket, reason} ->
            IO.puts "An error occurred on the socket."
            {ip, port, reason}
        after
          @timeout ->
            IO.puts ":gen_tcp.send/2 timed out after #{div(@timeout,  1_000)} seconds."
            # :inet.setopts(socket, [active: :once])
            handshake(peers, message)
        end
      {:error, :timeout} ->
        IO.puts ":gen_tcp.connect/2 timed out after #{div(@timeout, 1_000)} seconds."
        handshake(peers, message)
      {:error, reason} ->
        {:error, reason}
    end

  end

  def handshake(_, message) do
    IO.puts "No more peers."
  end
end
