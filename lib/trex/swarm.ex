defmodule Trex.Swarm do
  @moduledoc """
  Manage peer connections.
  """

  use Supervisor

  alias Trex.Peer
  alias Trex.Protocol
  require Logger

  # TODO: add to config?
  @num_peers 10
  @port 6881
  @timeout 2_000

  # TODO: retain state after crash?
  def start_link do
    case Supervisor.start_link(__MODULE__, [], name: __MODULE__) do
      {:ok, _} = ok ->
        ok
      {:error, reason} = error ->
        error
    end
  end

  def spawn_peer(peer) do
    Supervisor.start_child(Trex.Swarm, [peer])
  end

  # TODO: pass in handshake and id
  def init(_) do
    handshake_msg = "handshake"
    # handshake_msg =
    #   Protocol.encode(:handshake, <<0::size(64)>>, info_hash, peer_id)

    # TODO: handle error
    {:ok, lsocket} =
      :gen_tcp.listen(@port, [:binary, active: 1])

    children = [
      # worker(Trex.Peer, [])
      # Pass the listen socket to each peer.
      worker(Trex.Server, [lsocket, handshake_msg, peer, protocol])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def connect({peers, info_hash, peer_id}) when is_binary(peers) do
    message =
      Protocol.encode(:handshake, <<0::size(64)>>, info_hash, peer_id)

    peers
    |> parse_peers_binary
    |> Enum.take_random(@num_peers)
    |> Enum.map(&(spawn_peer(&1)))
    # |> Enum.map(&handshake(&1, message))
  end

  def handshake({ip, port}, message) do
    case :gen_tcp.connect(ip, port, [:binary, active: false], @timeout) do
      {:ok, socket} ->
        Logger.debug("#{to_dotted_ip(ip)}:#{port} connected.")
        :inet.setopts(socket, [active: true])
        :gen_tcp.send(socket, message)
        receive do
          {:tcp, socket, data} ->
            Logger.debug("Handshake succeeded.")
    #
    #         # Enter peer loop and process messages list.
    #         # Handle peer swarm here as well.
    #         # But for now, handle just one peer connection.
    #         # {:ok, peer} = Peer.start_link(socket)
    #
    #         # Wait for bitfield message here?
    #         # receive do
    #         # after
    #         #   3_000
    #         # end
    #         # loop(socket, data)
    #
    #       {:tcp_closed, _socket} ->
    #         Logger.debug("Socket is closed.")
    #         handshake(message, peers)
    #       {:tcp_error, reason} ->
    #         Logger.debug("TCP error")
    #         Logger.debug(reason)
    #         handshake(message, peers)
    #       after
    #         @timeout ->
    #           Logger.debug("Socket timed out.")
    #           handshake(message, peers)
        end
    #   {:error, :timeout} ->
    #     Logger.debug("#{dotted_ip}:#{port} timed out.")
    #     handshake(message, peers)
    #   {:error, :econnrefused} ->
    #     Logger.debug("#{dotted_ip}:#{port} refused to connect")
    #     handshake(message, peers)
    #   {:error, reason} ->
    #     Logger.debug(reason)
    #     handshake(message, peers)
    end
  end

  def handshake(_message, []) do
    # TODO: retry connecting after
    Logger.debug("Peer list exhausted.")
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

  # TODO: manage multiple socket connections
  # defp loop(socket, data) do
  #   case Protocol.decode(data) do
  #     {[], _} ->
  #       Logger.debug "No message received."
  #       send_message(socket, :keep_alive)
  #     {messages, rest} ->
  #       Enum.each(messages, fn %{type: type} = message ->
  #         IO.inspect message
  #         case type do
  #           :handshake ->
  #             Logger.debug "Handshake message received."
  #             send_message(socket, :interested)
  #           :keep_alive ->
  #             Logger.debug "Keep alive message received."
  #             send_message(socket, :interested)
  #           :unchoke ->
  #             Logger.debug "Unchoke message received."
  #             send_message(socket, :keep_alive)
  #           _ ->
  #             Logger.debug "Other message received."
  #             send_message(socket, :keep_alive)
  #             IO.inspect messages
  #         end
  #       end)
  #   end
  # end
  #
  # defp send_message(socket, type) do
  #   message  = Protocol.encode(type)
  #   # :inet.setopts(socket, [active: :once])
  #   :gen_tcp.send(socket, message)
  #
  #   receive do
  #     {:tcp, socket, data} ->
  #       loop(socket, data)
  #     _ ->
  #       Logger.debug "Error"
  #   after
  #     @timeout ->
  #       Logger.debug("Peer timed out.")
  #       loop(socket, message)
  #   end
  # end

  # defp loop_through_messages(messages) do
  #   loop_through_messages(messages, [])
  # end
  #
  # defp loop_through_messages([head | tail], acc) do
  # end
  #
  # defp loop_through_messages(_, acc) do
  # end

  defp to_dotted_ip(ip) do
    ip
    |> Tuple.to_list
    |> Enum.join(".")
  end
end
