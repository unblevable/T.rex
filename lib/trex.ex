defmodule Trex do
  @moduledoc false

  use Application

  @doc false
  def start(_type, _args) do
    Trex.Supervisor.start_link
  end

  @doc false
  def a(torrent \\ "priv/ubuntu.torrent") do
    {:ok, pid} = Trex.Cli.main([torrent])
    pid
  end

  @doc false
  def b do
    {:ok, pid} = Trex.Cli.main(["priv/flagfromserver.torrent"])
    pid
  end
end
