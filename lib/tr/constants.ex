defmodule Tr.Constants do
  @moduledoc false

  defmacro __using__(_) do
    # TODO: document
    quote do
      @client_id "RX"
      @port 6881
    end
  end
end
