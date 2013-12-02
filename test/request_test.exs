defmodule RequestTest do

  use ExUnit.Case, async: true

  # import Trex.Request

  test "creates request url" do
    dict = HashDict.new
    |>  HashDict.put(:announce, :banana)
    |>  HashDict.put(:cherry, :dragonfruit)
  end

end
