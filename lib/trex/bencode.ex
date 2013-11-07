defmodule Trex.Bencode do

  @moduledoc"""
  BEncode decoder and encoder
  """

  @doc"""
  Take a binary (from a .torrent file) and a Dict implementation and output a
  dictionary of that type (in no particular order) and contains the file's metadata.
  """
  def decode(bin, dict_impl // ListDict ) do
    # exclude the trailing character
    { _, dict } = bin |> String.rstrip |> parse_bin(dict_impl)
    { :ok, dict }
  end

  @doc"""
  Take a dictionary containing torrent metadata and encode it into a .torrent
  file.
  """
  def encode(dict), do: unparse(dict)

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
    # recurse to grab each key and recurse again to grab each value
    { key_tail, key } = parse_bin(bin, dict_impl)
    { val_tail, val } = parse_bin(key_tail, dict_impl)

    parse_dict(val_tail, Dict.put(acc, key, val), dict_impl)
  end

  defp unparse(int) when is_integer(int), do: "i" <> to_string(int) <> "e"
  defp unparse(str) when is_binary(str),  do: (size(str) |> to_string) <> ":" <> str
  defp unparse({ :list, list }) when is_list(list) do
    # recurse on each item of a list
    comprehension = lc x inlist list, do: unparse(x)
    "l" <> to_string(comprehension) <> "e"
  end
  defp unparse({ :dict, dict }) do
    # sort the dictionary and encode each key and then each value; wrap the
    # resulting key-value pair into a list (for ease) and reduce the list into
    # a concatenated string
    dict_as_string = Enum.sort(dict, fn({ k0, _v0 }, { k1, _v1 }) -> k0 < k1 end)
    |> Enum.map(fn({ k, v }) when is_integer(k) or is_binary(k) -> List.wrap(unparse k) ++ List.wrap(unparse v) end)
    |>  List.flatten
    |>  List.foldr "", fn(x, acc) -> to_string(x) <> to_string(acc) end

    "d" <> dict_as_string <> "e"
  end

end
