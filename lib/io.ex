defmodule Trex.IO do

  def read() do
    File.read("resrc/big.torrent")
    |>  parse
  end

  def write() do
    { :ok, bin_write } = File.open("resrc/sample.txt", [:read, :write])
    { :ok, bin_read } = File.read("resrc/big.torrent")
    to_write = Trex.Bencode.decode(bin_read, ListDict)
    :io.write(bin_write, to_write)
    File.close(bin_write)
    File.close(bin_read)
  end

  def parse({ :error, reason }), do: :file.format_error reason
  def parse({ :ok, bin }), do: Trex.Bencode.decode(bin, ListDict)

end
