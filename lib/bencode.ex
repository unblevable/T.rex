defmodule Trex.Bencode do

  @moduledoc"""
  BEncode decoder and encoder
  """

  @doc"""
  Take a binary (from a .torrent file) and a Dict implementation and output a
  dictionary of that type (in no particular order) and contains the file's metadata.

  @default ListDict
  """
  def decode(bin, dict_impl = module // ListDict ) do
    # exclude the trailing newline character
    { _, dict } = parse_bin(bin, dict_impl)
    dict
  end

  defp parse_bin(<<?i::utf8, tail::binary>>, _dict_impl), do: parse_int(tail, [])
  defp parse_bin(<<?l::utf8, tail::binary>>, dict_impl),  do: parse_list(tail, [], dict_impl)
  defp parse_bin(<<?d::utf8, tail::binary>>, dict_impl),  do: parse_dict(tail, dict_impl.new, dict_impl)
  defp parse_bin(bin, _dict_impl),                        do: parse_str(bin, [])

  defp parse_int(<<?e::utf8, tail::binary>>, acc),    do: { tail, list_to_integer(acc) }
  defp parse_int(<<head::utf8, tail::binary>>, acc),  do: parse_int(tail, acc ++ List.wrap(head))

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

  defp parse_list(<<?e::utf8, tail::binary>>, acc, _dict_impl) do
    # add type info for encoder
    { tail, { :list, acc } }
  end
  defp parse_list(bin, acc, dict_impl) do
    # recurse to check for other lists, etc.
    { val_tail, val } = parse_bin(bin, dict_impl)
    parse_list(val_tail, acc ++ [val], dict_impl)
  end

  defp parse_dict(<<?e::utf8, tail::binary>>, acc, _dict_impl) do
    # add type info for encoder
    { tail, { :dict, acc } }
  end
  defp parse_dict(bin, acc, dict_impl) do
    # recurse to grab the key and recurse again to grab the value
    { key_tail, key } = parse_bin(bin, dict_impl)
    { val_tail, val } = parse_bin(key_tail, dict_impl)

    parse_dict(val_tail, dict_impl.put(acc, key, val), dict_impl)
  end

  @doc"""
  Take a dictionary containing torrent metadata and encode it into a .torrent
  file.
  """

  defp encode(int, acc) when is_integer(int), do: ?i <> to_string(int) <> ?e
  defp encode(str, acc) when is_binary(str), do: (String.length(str) |> to_string) <> ?: <> str

  # defp encode(Dict.empty(dict)) do when is_tuple or is_list
  #   Dict.to_list(dict)
  #   |>  List.map( jjj
  # end

  # defp encode(enum) when is_integer

end
