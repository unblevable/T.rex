defmodule Trex.Peer do
  @moduledoc """
  Peer communication.
  """

  alias Trex.Messages

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
    pstrlen = <<byte_size(pstr)>>
    message = pstrlen <> pstr <> <<0, 0, 0, 0, 0, 0, 0, 0>> <> info_hash <> peer_id

    peers = parse_peers_binary(peers, [])
    handshake(peers, message, {info_hash})

    # TODO: change into a record?
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
  def parse_peers_binary(<<a, b, c, d, port::integer-size(16), rest::bytes>>, acc) do
    ipv4 = {a, b, c, d}
    parse_peers_binary(rest, [{ipv4, port} | acc])
  end

  def parse_peers_binary(_, acc) do
    acc
  end

  # TODO: cleanup, refactor into more functions?
  # TODO: [active: :once]
  def handshake([{ip, port} | peers], message, state) do
    case :gen_tcp.connect(ip, port, [:binary, active: :once], @timeout) do
      {:ok, socket} ->
        receive_handshake(peers, message, socket, state)
      {:error, :timeout} ->
        IO.puts ":gen_tcp.connect/2 timed out after #{div(@timeout, 1_000)} seconds."
        handshake(peers, message, state)
      {:error, :econnrefused} ->
        IO.puts ":gen_tcp.connect/2 was refused a connection."
        handshake(peers, message, state)
      {:error, reason} ->
        {:error, reason}
    end

  end

  def handshake(_, _message, _state) do
    IO.puts "No more peers."
  end

  def receive_handshake(peers, message, socket, state) do
    :gen_tcp.send(socket, message)
    receive do
      {:tcp, socket, data} ->
        case data do
          <<
            19,
            "BitTorrent protocol",
            reserved::bytes-size(8),
            info_hash::bytes-size(20),
            peer_id::bytes-size(20),
            rest::bytes
          >> ->
            {info} = state
            if info_hash == info  do
              IO.puts "success"
              # TODO: handle tracking peers by id
              Messages.start(socket)
              Messages.get(rest)
            else
              IO.puts "info_hashes don't match"
            end
            :ok
          _ ->
            IO.puts "rest"
            IO.inspect data
        end

        {socket, data}
      {:tcp_closed, socket} ->
        IO.puts "The socket is closed."
        :inet.setopts(socket, [active: :once])
        handshake(peers, message, state)
      {:tcp_error, socket, reason} ->
        IO.puts "An error occurred on the socket.: #{reason}"
    after
      @timeout ->
        IO.puts ":gen_tcp.send/2 timed out after #{div(@timeout,  1_000)} seconds."
        :inet.setopts(socket, [active: :once])
        handshake(peers, message, state)
    end
  end
end
