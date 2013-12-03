defmodule Trex.Client do

  @peer_id_prefix "-RX" <> Trex.Utils.get_version <> "-"
  @len_peer_id_rand 12
  @port "6881"

  def id do
      hash = :crypto.hash(:md5, System.get_pid)
      |> String.slice(2, @len_peer_id_rand)

      @peer_id_prefix <> hash
  end

  def port do
    @port
  end
end
