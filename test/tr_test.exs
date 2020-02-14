defmodule TrTest do
  use ExUnit.Case
  doctest Tr

  test "greets the world" do
    assert Tr.hello() == :world
  end
end
