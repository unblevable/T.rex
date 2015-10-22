defmodule Trex.Swarm do
  @moduledoc """
  Manage peer connections.
  """

  require Logger

  alias Trex.Protocol

  @timeout 2_000
  @port 6881

  def connect({peers, info_hash, peer_id}) when is_binary(peers) do
    peers = parse_peers_binary(peers)

    # create handshake message
    Protocol.encode(:handshake, <<0::size(64)>>, info_hash, peer_id)
    |> handshake(peers)
  end

  def handshake(message, [{ip, port} | peers]) do
    # TODO: debug only
    dotted_ip =
      ip
      |> Tuple.to_list
      |> Enum.join(".")

    case :gen_tcp.connect(ip, port, [:binary, active: false], @timeout) do
      {:ok, socket} ->
        :inet.setopts(socket, [active: :once])
        :gen_tcp.send(socket, message)
        receive do
          {:tcp, _socket, data} ->
            Protocol.decode(data)
            Logger.debug("Handshake succeeded.")
          {:tcp_closed, _socket} ->
            Logger.debug("Socket is closed.")
            handshake(message, peers)
          {:tcp_error, reason} ->
            Logger.debug(reason)
            handshake(message, peers)
          after
            @timeout ->
              Logger.debug("Socket timed out")
              handshake(message, peers)
        end
      {:error, :timeout} ->
        Logger.debug("#{dotted_ip}:#{port} timed out.")
        handshake(message, peers)
      {:error, :econnrefused} ->
        Logger.debug("#{dotted_ip}:#{port} refused to connect")
        handshake(message, peers)
      {:error, reason} ->
        Logger.debug(reason)
        handshake(message, peers)
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
  defp parse_peers_binary(binary), do: parse_peers_binary(binary, [])
  defp parse_peers_binary(<<
    a, b, c, d,
    port::integer-size(16),
    rest::bytes
  >>, acc),                        do: parse_peers_binary(rest, [{{a, b, c, d}, port} | acc])
  defp parse_peers_binary(_, acc), do: acc
end
