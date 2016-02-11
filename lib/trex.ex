defmodule Trex do
  @moduledoc false

  use Application

  @event_manager_name Trex.EventManager
  @main_supervisor_main Trex.Supervisor

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(GenEvent, [[name: @event_manager_name]]),
      worker(Trex.Cli, [@event_manager_name], [[name: Trex.Cli]]),
      supervisor(Trex.Swarm, [])
    ]

    opts = [name: @main_supervisor_name, strategy: :one_for_one]
    Supervisor.start_link(children, opts)
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
