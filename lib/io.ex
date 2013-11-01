defmodule Trex.IO do

  def read() do
    File.read("resrc/big.torrent")
    |>  parse
  end

  def parse({ :error, reason }), do: :file.format_error reason
  def parse({ :ok, binary }), do: Trex.Bencode.decode(binary, ListDict)

end
