defmodule Trex.Peer do
  use GenServer
  require Logger

  # Client API ---------------------------------------------------------------

  def start_link(state) do
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

  def set(data) do
    GenServer.cast(:peer, data)
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
    {:reply, state[:peer_id], state}
  end

  def handle_call({:get, :info_hash}, _from, state) do
    {:reply, state[:info_hash], state}
  end

  def handle_cast({:set, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end
end
