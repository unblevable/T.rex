defmodule Trex.Server do
  use GenServer

  require Logger

  # Client -------------------------------------------------------------------

  def start_link(peer) do
    {ip, port} = peer
    state = %{ip: ip, port: port, lsocket: nil}
    GenServer.start_link(__MODULE__, [state], [])
  end

  # Server -------------------------------------------------------------------

  def init(peer) do
    opts = [:binary, [reuseaddr: true, active: :once]]
    # TODO: cast to another process
    case :gen_tcp.listen(8090, opts) do
      {:ok, _socket} ->
        new_state = peer
        {:ok, accept(new_state)}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  ## Callbacks ===============================================================

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
    {:noreply, accept(state)}
  end


  ## TCP =====================================================================

  def handle_info({:tcp, _socket, _data}) do
    Logger.debug("Handshake succeeded.")
  end

  ## Errors ==================================================================

  # TODO: add in a timeout
  def handle_info({:tcp_closed, _socket}) do
    Logger.debug("The socket is closed.")
    # Try another peer.
  end

  def handle_info({:tcp_error, reason}) do
    Logger.debug("TCP error: #{reason}")
    # Try another peer.
  end

  # @lsocket - listen socket
  def accept_loop({_server, lsocket, {_module, _func}}) do
    {:ok, _socket} = :gen_tcp.accept(lsocket)

    # Let the server spawn a new process and replace this loop with the echo
    # loop, to avoid blocking.
    GenServer.cast(__MODULE__, :accepted)
    # module.func(socket)
  end

  def accept(state) do
    # :proc_lib.spawn(__MODULE__, :accept_loop, [{self(), lsocket, loop}])
    state
  end
end
