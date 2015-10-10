defmodule Trex.Node do
  use GenServer

  alias Trex.Node

  @timeout 2_500
  @port 6881

  # Client API

  def start_link(state) do
    {peer_id, _} = state
    GenServer.start_link(__MODULE__, state, name: peer_id, debug: [:trace])
  end

  # Server callbacks

  def init(state) do
    # `reuseaddr: true` allows us to reuse the address if the listener crashes
    case :gen_tcp.listen(@port, [:binary, reuseaddr: true]) do
      {:ok, listen} ->
        loop(listen)
      {:error, reason} ->
        IO.puts "Error:"
        IO.inspect reason
    end

    {:ok, state}
  end

  def loop(socket) do
    :inet.setopts(socket, [active: :once])
    # TODO: @timeout
    case :gen_tcp.accept(socket) do
      {:ok, accept} ->
        receive do
          {:tcp, socket, data} ->
            GenServer.cast(self(), {:message, data})
            loop(socket)
          {:tcp_closed, socket} ->
            IO.puts "Socket closed."
          {:tcp_error, socket, reason} ->
            IO.puts "Error:"
            IO.inspect reason
        end
      {:error, reason} ->
        IO.puts "Error:"
        IO.inspect reason
    end
  end

  def handle_cast({:message, message}, _from, state) do

    {:noreply, state}
  end
end
