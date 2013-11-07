defmodule Trex.Utils do

  def impl_dict?(module) do
    Dict.__info__(:exports)
      |>  Dict.drop([:__behaviour__, :behaviour_info])
      |>  Enum.all?((&1 in module.__info__(:exports)))
  end

end
