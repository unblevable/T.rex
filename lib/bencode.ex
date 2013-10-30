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

  @doc"""
  Parse a .torrent binary by data type, i.e. integer, string, list, dictionary
  """
  def parse_bin(<<?i::utf8, tail::binary>>),  do: parse_int(tail, [])
  def parse_bin(<<?l::utf8, tail::binary>>),  do: parse_list(tail, [])
  def parse_bin(<<?d::utf8, tail::binary>>),  do: parse_dict(tail, HashDict.new)
  def parse_bin(bin),                         do: parse_str(bin, [])

  @doc"""
  Parse a BEncoded integer, which is encoded as i<integer>e
  """
  def parse_int(<<?e::utf8, tail::binary>>, acc),     do: { tail, list_to_integer(acc) }
  def parse_int(<<head::utf8, tail::binary>>, acc),   do: parse_int(tail, acc ++ List.wrap(head))

  @doc"""
  Parse a BEncoded string, which is encoded as <length>:<string>
  """
  def parse_str(<<?:::utf8, tail::binary>>, acc) do
    # extract the integer that denotes the string's length
    str_len = list_to_integer acc

    # extract what remains of the file to parse
    <<str::[binary, size(str_len)], rem::binary>> = tail

     { rem, str }
  end
  def parse_str(<<head::utf8, tail::binary>>, acc) do
    parse_str(tail, acc ++ List.wrap(head))
  end

  @doc"""
  Parse a BEncoded list, which is encoded as l<list>e
  """
  def parse_list(<<?e::utf8, tail::binary>>, acc) do
    { tail, acc }
  end
  def parse_list(bin, acc) do
    # recurse to check for other lists, etc.
    { val_tail, val } = parse_bin(bin)
    parse_list(val_tail, acc ++ [val])
  end

  @doc"""
  Parse a BEncoded dictionary, which is encoded as d<key><value>e. Multiple
  key-value pairs can be specified
  """
  def parse_dict(<<?e::utf8, tail::binary>>, acc) do
    { tail, acc }
  end
  def parse_dict(bin, acc) do
    # recurse to grab the key and recurse again to grab the value
    { key_tail, key } = parse_bin(bin)
    { val_tail, val } = parse_bin(key_tail)

    parse_dict(val_tail, HashDict.put(acc, key, val))
  end

  @doc"""
  Take a dictionary containing torrent metadata and encode it into a .torrent
  file.
  """
  # to be implemented

end
