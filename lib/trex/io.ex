defmodule Trex.IO do

  @defmodule"""
  Handle file IO
  """

  def read(file) do
    File.read(file)
  end

  def parse({ :error, reason }), do: :file.format_error reason
  def parse({ :ok, bin }), do: Trex.Bencode.decode(bin, HashDict)

end
