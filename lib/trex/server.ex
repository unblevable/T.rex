defmodule Trex.Server do
  @moduledoc false

  use GenServer

  require Logger

  @opts [:binary, active: 1]
  @timeout 2_000

  # Client -------------------------------------------------------------------

  @doc false
  def start_link(ip, port, lsocket, handshake_msg) do
    state = %{
      ip: ip,
      port: port,
      lsocket: lsocket,
      handshake_msg: handshake_msg
    }

    GenServer.start_link(__MODULE__, state, [])
  end

  # Server -------------------------------------------------------------------

  def init(state) do
    socket =
      connect(state.ip, state.port)

    handshake(socket, state.handshake_msg)

    {:ok, Map.put(state, :socket, socket)}
  end

  ## TCP =====================================================================

  def handle_info({:tcp, _socket, _data}, state) do
    Logger.debug("Handshake succeeded.")

    {:noreply, state}
  end

  # TODO: add in a timeout
  def handle_info({:error, reason}, state) do
    case reason do
      # :timeout ->
        # retry same peer?
      # :econnrefused ->
        # retry another peer?
      _ ->
        reason
    end

    {:noreply, state}
  end

  def handle_info({:tcp_passive, socket}, state) do
    Logger.debug("The socket is in passive mode.")
    :inet.setopts(socket, [active: 1])

    {:noreply, state}
  end

  # TODO: add in a timeout
  def handle_info({:tcp_closed, _socket}, state) do
    Logger.debug("The socket is closed.")
    # Try another peer.

    {:noreply, state}
  end


  def handle_info({:tcp_error, reason}, state) do
    Logger.debug("A TCP error has occurred: #{reason}")
    # Try another peer.

    {:noreply, state}
  end

  # Helpers ------------------------------------------------------------------

  defp connect(ip, port) do
    {:ok, socket} =
      :gen_tcp.connect(ip, port, @opts, @timeout)

    Logger.debug("#{to_dotted_ip(ip)}:#{port} connected.")

    socket
  end

  defp handshake(socket, msg) do
    :gen_tcp.send(socket, msg)
  end

  defp to_dotted_ip(ip) do
    ip
    |> Tuple.to_list
    |> Enum.join(".")
  end
end
