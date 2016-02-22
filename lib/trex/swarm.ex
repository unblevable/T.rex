defmodule Trex.Swarm do
  @moduledoc """
  Supervise peer connections.
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def start_peer(supervisor, ip, port, lsocket, handshake_msg) do
    Supervisor.start_child(supervisor, [ip, port, lsocket, handshake_msg])
  end

  def init(_) do
    children = [
      # worker(Trex.Peer, [])
      worker(Trex.Server, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
