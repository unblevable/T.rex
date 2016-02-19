defmodule Trex.Supervisor do
  @moduledoc """
  The top-level supervisor.
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    children = [
      # worker(Trex.Swarm, [])
      supervisor(Trex.Spring, []),
      worker(Trex.Cli, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
