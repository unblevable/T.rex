defmodule Trex.Utils do

  def impl_dict?(module) do
    filtered = Dict.__info__(:exports)
    |>  Dict.drop([:__behaviour__, :behaviour_info, :update])

    Enum.all?(filtered, fn(x) -> x in module.__info__(:exports) end)
  end

end
