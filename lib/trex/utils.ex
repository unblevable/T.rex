defmodule Trex.Utils do

  @version "0001"

  def impl_dict?(module) do
    filtered = Dict.__info__(:exports)
    |>  Dict.drop([:__behaviour__, :behaviour_info, :update])

    Enum.all?(filtered, fn(x) -> x in module.__info__(:exports) end)
  end

  def get_version do
    @version
  end

end
