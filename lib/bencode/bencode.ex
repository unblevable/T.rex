# T rex
defmodule Trex.Bencode do

  def decode(integer) when is_integer(integer) do
  end
  def decode(string) when is_binary(string) do
    IO.puts string
  end

  def decode(list) when is_list(list) do
  end

  def decode(dictionary) when is_record(dictionary) do
  end

  def encode(string) do
  end

  # read and parse
  def parse(file) do
    format = fn
      { :ok, binary }   -> String.codepoints binary |> find_index at(e)
      { :error, reason }  -> :file.format_error reason
    end

    # split by colons
    # merge the number in the previon

    File.read("resrc/flagfromserver.torrent") |> format.()
  end

end
