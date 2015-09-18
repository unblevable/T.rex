defmodule CliTest do
  use ExUnit.Case, async: true

  doctest Trex.Cli
  alias Trex.Cli
  import ExUnit.CaptureIO

  test "passing no arguments outputs usage info" do
    assert capture_io(fn ->
      Cli.run([])
    end) == capture_io(fn ->
      Cli.run(["--help"])
    end)
  end
end
