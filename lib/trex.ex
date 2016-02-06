defmodule Trex do
  @moduledoc false

  use Application

  @event_manager Trex.EventManager
  @main_supervisor Trex.Supervisor

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    #TODO: prevent callback spaghetti
    case GenEvent.start_link([name: @event_manager]) do
      {:ok, pid} = ok ->
        children = [
          worker(Trex.Cli, [pid], [[name: Trex.Cli]]),
          supervisor(Trex.Swarm, [[name: Trex.Swarm]])
        ]

        opts = [name: @main_supervisor, strategy: :one_for_one]
        Supervisor.start_link(children, opts)

        ok
      {:error, _} = error ->
        error
    end
  end

  @doc false
  def main(args) do
    Trex.Cli.run(args)
  end

  @doc false
  def ubuntu do
    Trex.Cli.run(["priv/ubuntu.torrent"])
  end

  @doc false
  def flag do
    Trex.Cli.run(["priv/flagfromserver.torrent"])
  end
end
