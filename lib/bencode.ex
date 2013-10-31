defmodule Trex.Bencode do

  @moduledoc"""
  BEncode decoder and encoder
  """

  @doc"""
  Take a binary (from a .torrent file) and output a dictionary (as of now, with
  no particular order) that contains the file's metadata.
  """
  def decode(bin) do
    # exclude the trailing newline character
    { _, dict } = parse_bin(bin)
    dict
  end

  defp parse_bin(<<?i::utf8, tail::binary>>),  do: parse_int(tail, [])
  defp parse_bin(<<?l::utf8, tail::binary>>),  do: parse_list(tail, [])
  defp parse_bin(<<?d::utf8, tail::binary>>),  do: parse_dict(tail, HashDict.new)
  defp parse_bin(bin),                         do: parse_str(bin, [])

  defp parse_int(<<?e::utf8, tail::binary>>, acc),     do: { tail, list_to_integer(acc) }
  defp parse_int(<<head::utf8, tail::binary>>, acc),   do: parse_int(tail, acc ++ List.wrap(head))

  defp parse_str(<<?:::utf8, tail::binary>>, acc) do
    # extract the integer that denotes the string's length
    str_len = list_to_integer acc

    # extract what remains of the file to parse
    <<str::[binary, size(str_len)], rem::binary>> = tail

     { rem, str }
  end
  defp parse_str(<<head::utf8, tail::binary>>, acc) do
    parse_str(tail, acc ++ List.wrap(head))
  end

  defp parse_list(<<?e::utf8, tail::binary>>, acc) do
    { tail, acc }
  end
  defp parse_list(bin, acc) do
    # recurse to check for other lists, etc.
    { val_tail, val } = parse_bin(bin)
    parse_list(val_tail, acc ++ [val])
  end

  defp parse_dict(<<?e::utf8, tail::binary>>, acc) do
    { tail, acc }
  end
  defp parse_dict(bin, acc) do
    # recurse to grab the key and recurse again to grab the value
    { key_tail, key } = parse_bin(bin)
    { val_tail, val } = parse_bin(key_tail)

    parse_dict(val_tail, HashDict.put(acc, key, val))
  end

  @doc"""
  Take a dictionary containing torrent metadata and encode it into a .torrent
  file.
  """
  def encode(dict) do
    Dict.to_list(dict)
  end

  defp encode(int, acc) when is_integer(int) do
    "i" <> to_string int <> "e"
  end

  defp encode(str, acc) when is_binary(str) do
  end

  defp encode(bin, acc) when is_list(bin) do
  end

  defp encode(bin, acc) do
  end

end
