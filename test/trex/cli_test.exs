defmodule CliTest do
  use ExUnit.Case, async: true

  doctest Trex.Cli
  alias Trex.Cli

  test "passing no arguments outputs usage info" do
    assert Cli.run([]) == Cli.run(["--help"])
  end
end
