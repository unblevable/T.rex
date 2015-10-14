defmodule Trex do
  @moduledoc """
  """

  @doc false
  def main(args) do
    Trex.Cli.run(args)
  end

  @doc "testing"
  def ubuntu do
    Trex.Cli.run(["priv/ubuntu.torrent"])
  end

  def flag do
    Trex.Cli.run(["priv/flagfromserver.torrent"])
  end
end
