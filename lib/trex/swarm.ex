defmodule Trex.Swarm do
  @moduledoc """
  Supervise peer connections.
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def start_peer(supervisor, peer_state) do
    Supervisor.start_child(supervisor, [peer_state])
  end

  def init(_) do
    children = [
      # worker(Trex.Peer, [])
      worker(Trex.Server, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
