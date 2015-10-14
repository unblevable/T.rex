defmodule Trex.Peer do
  use GenServer
  require Logger

  alias Trex.Peer
  alias Trex.Peer.Messages

  @timeout 1_000
  @port 6881

  def connect(response) do
    %{
      interval: _interval,
      # "tracker id": tracker_id,
      # complete: seeders,
      # incomplete: leechers,
      peers: peers_binary
    } = response

    peers = parse_peers_binary(peers_binary)

    peer_id = Peer.get(:peer_id)
    info_hash = Peer.get(:info_hash)

    # Is the peer interested in this client?
    Peer.set({:interested?, false})
    # Is this client choking the peer?
    Peer.set({:choked?, true})

    # create handshake message
    pstr = "BitTorrent protocol"
    pstrlen = <<byte_size(pstr)>>
    message = pstrlen <> pstr <> <<0, 0, 0, 0, 0, 0, 0, 0>> <> info_hash <> peer_id

    handshake(message, peers)
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
          {:tcp, socket, data} ->
            Messages.get(data)
            recurse(socket)
            # GenServer.cast(self(), {:message, data})
          {:tcp_closed, socket} ->
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
    Logger.debug("No more peers")
  end

  def recurse(socket) do
    :inet.setopts(socket, [active: :once])
    Messages.send_interested(socket)
    receive do
      data ->
        case Messages.get(data) do
          :error ->
            recurse(socket)
          response ->
            response
        end
      after
        @timeout ->
          Logger.debug("Sending `interested` again.")
          recurse(socket)
    end
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

  # Client API ---------------------------------------------------------------

  def start_link({_peer_id, _info_hash} = state) do
    # TODO: create unique name for process
    GenServer.start_link(__MODULE__, state, name: :peer)
  end

  # def accept(port \\ @port) do
  #   # `reuseaddr: true` allows us to reuse the address if the listener crashes
  #   case :gen_tcp.listen(port, [:binary, reuseaddr: true]) do
  #     {:ok, listen} ->
  #       loop(listen)
  #     {:error, reason} ->
  #       Logger.error(reason)
  #   end
  # end

  def get(data) do
    GenServer.call(:peer, {:get, data})
  end

  # Server callbacks ---------------------------------------------------------

  def init(state) do
    {:ok, state}
  end

  # def handle_cast({:message, message}, _from, state) do
  #   Messages.get(message)
  #   {:noreply, state}
  # end

  def handle_call({:get, :peer_id}, _from, state) do
    {peer_id, _} = state
    {:reply, peer_id, state}
  end

  def handle_call({:get, :info_hash}, _from, state) do
    {_, info_hash} = state
    {:reply, info_hash, state}
  end
end
