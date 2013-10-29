defmodule Trex.Bencode do

  @moduledoc"""
  BEncode decoder and encoder
  """

  @doc"""
  Take a binary (from a .torrent file) and output a HashDict containing
  the file's metadata
  """
  def decode(bin) do
    { _, dict } =  String.rstrip(bin) |> parse_bin
    dict
  end

  @doc"""
  Parse a .torrent binary by data type, i.e. integer, string, list, dictionary
  """
  def parse_bin(<<?i::utf8, tail::binary>>),  do: parse_int(tail, [])
  def parse_bin(<<?l::utf8, tail::binary>>),  do: parse_list(tail, [])
  def parse_bin(<<?d::utf8, tail::binary>>),  do: parse_dict(tail, HashDict.new)
  def parse_bin(<<?e::utf8, tail::binary>>),  do: parse_bin(tail)
  def parse_bin(bin),                         do: parse_str(bin, [])

  @doc"""
  Parse a BEncoded integer, which is encoded as i<integer>e
  """
  def parse_int(<<?e::utf8, tail::binary>>, acc),     do: { tail, list_to_integer(acc) }
  def parse_int(<<head::utf8, tail::binary>>, acc),   do: parse_int(tail, acc ++ List.wrap(head))

  @doc"""
  Parse a BEncoded list, which is encoded as l<list>e
  """
  def parse_list(<<?e::utf8, tail::binary>>, acc) do
    :io.format("found EEEEE")
    { tail, acc }
  end
  def parse_list(bin = <<head::utf8, tail::binary>>, acc) do
    :io.format("list~n")
    case parse_bin(bin) do
      { val_tail, val } -> parse_list(val_tail, acc ++ List.wrap(val))
      end_tail -> { end_tail, List.flatten acc }
    end
  end
  def parse_list(_, acc), do: { nil, acc }

  @doc"""
  Parse a BEncoded string, which is encoded as <length>:<string>
  """
  def parse_str(<<?:, tail::binary>>, acc) do
    # extract the integer that denotes the string's length
    str_len = list_to_integer acc

    tail_len = byte_size(tail) - str_len
    if tail_len < 0, do: tail_len = 0

    # return the accumalator without the <string> and the <string>
    { String.slice(tail, str_len, tail_len), String.slice(tail, 0, str_len) }
  end
  def parse_str(<<head::utf8, tail::binary>>, acc) do
    parse_str(tail, acc ++ List.wrap(head))
  end
  def parse_str(_, acc), do: nil

  @doc"""
  Parse a BEncoded dictionary, which is encoded as d<key><value>e. Multiple
  key-value pairs can be specified
  """
  def parse_dict(bin, acc) do
    # parse the key first and the value second
    case parse_bin(bin) do
      { key_tail, key } ->
        :io.format("key: ~p~n", [key])
        case parse_bin(key_tail) do
          { val_tail, val } ->
            # :io.format("val: ~p~n", [val])
            parse_dict(val_tail, HashDict.put(acc, key, val))
            end_tail -> { end_tail, acc }
        end
        end_tail -> { end_tail, acc }
    end

  end

  @doc"""
  Take a dictionary containing torrent metadata and encode it into a .torrent
  file.
  """
  # to be implemented

end
