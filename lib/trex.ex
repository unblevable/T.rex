defmodule Trex do
  @moduledoc false

  use Application

  @doc false
  def start(_type, _args) do
    Trex.Supervisor.start_link
  end

  @doc false
  def a do
    Trex.Cli.main(["priv/ubuntu.torrent"])
  end

  @doc false
  def b do
    Trex.Cli.main(["priv/flagfromserver.torrent"])
  end
end
