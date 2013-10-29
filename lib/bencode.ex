defmodule Trex.Bencode do

  @moduledoc"""
  BEncode decoder and encoder
  """

  @doc"""
  Take a binary (from a .torrent file) and output a HashDict containing
  the file's metadata
  """
  def decode(bin) do
    { _, dict } = parse_bin(bin)
    dict
  end

  @doc"""
  Parse a .torrent binary by data type, i.e. integer, string, list, dictionary
  """
  def parse_bin(<<?i::utf8, tail::binary>>), do: parse_int(tail, [])
  def parse_bin(<<?l::utf8, tail::binary>>), do: parse_list(tail, [])
  def parse_bin(<<?d::utf8, tail::binary>>), do: parse_dict(tail, HashDict.new)
  def parse_bin(str), do: parse_str(str, [])

  @doc"""
  Parse a BEncoded integer, which is encoded as i<integer>e
  """
  def parse_int(<<?e::utf8, tail::binary>>, acc),     do: { tail, list_to_integer(acc) }
  def parse_int(<<head::utf8, tail::binary>>, acc),   do: parse_int(tail, acc ++ List.wrap(head))

  @doc"""
  Parse a BEncoded list, which is encoded as l<list>e
  """
  def parse_list(<<?e::utf8, tail::binary>>, acc),    do: { tail, acc }
  def parse_list(<<head::utf8, tail::binary>>, acc),  do: parse_list(tail, acc ++ List.wrap(head))

  @doc"""
  Parse a BEncoded string, which is encoded as <length>:<string>

  [fix] Use size and read length of binary manually.
  """
  def parse_str(<<?:::utf8, tail::binary>>, acc) do
    # extract the integer that denotes the string's length
    str_len = list_to_integer acc
    tail_len = byte_size(tail)

    # return the accumalator without the <string> and the <string>
    { String.slice(tail, str_len, tail_len - str_len - 1), String.slice(tail, 0, str_len) }
  end
  def parse_str(<<head::utf8, tail::binary>>, acc), do: parse_str(tail, acc ++ List.wrap(head))

  @doc"""
  Parse a BEncoded dictionary, which is encoded as d<key><value>e. Multiple
  key-value pairs can be specified
  """
  def parse_dict(<<?e>>, acc) do
    IO.puts "found e"
    acc
  end
  def parse_dict(nil, acc), do: { nil, acc }
  def parse_dict(bin, acc) do
    # parse the key first and the value second
    { key_tail, key } = parse_bin(bin)

    case parse_bin(key_tail) do
      { val_tail, val } ->
        # :io.format("~p", [val])
        # :io.format("~p", [val_tail])
        parse_dict(val_tail, HashDict.put(acc, key, val))
      _acc -> :ok
    end
  end

  @doc"""
  Take a dictionary containing torrent metadata and encode it into a .torrent
  file.
  """
  # to be implemented

end
