defmodule Trex.Bencode do
  @moduledoc """
  Bencode (bee-encode) decoder and encoder.
  """

  @doc """
  Decode bencode types into corresponding Elixir data types.

  ## Examples

      iex> Trex.Bencode.decode("4:spam")
      "spam"

      iex> Trex.Bencode.decode("i3e")
      3

      iex> Trex.Bencode.decode("l4:spam4:eggse")
      ["spam", "eggs"]

      iex> Trex.Bencode.decode("d3:cow3:moo4:spam4:eggse")
      %{cow: "moo", spam: "eggs"}

      iex> Trex.Bencode.decode("d4:spaml1:a1:bee")
      %{spam: ["a", "b"]}

  """
  def decode(binary) do
    binary
    |> parse
    # Extract the decoded binary from the accumulator
    |> elem(1)
  end

  @doc """
  Encode Elixir data types into corresponding bencode types.

  ## Examples

      iex> Trex.Bencode.encode("spam")
      "4:spam"

      iex> Trex.Bencode.encode(3)
      "i3e"

      iex> Trex.Bencode.encode(["spam", "eggs"])
      "l4:spam4:eggse"

      iex> Trex.Bencode.encode(%{"cow" => "moo", "spam" => "eggs"})
      "d3:cow3:moo4:spam4:eggse"

      iex> Trex.Bencode.encode(%{spam: ["a", "b"]})
      "d4:spaml1:a1:bee"

  """
  def encode(data) do
    unparse(data)
  end

  defp parse(<<?i::utf8, tail::bytes>>), do: parse_integer(tail, [])
  defp parse(<<?l::utf8, tail::bytes>>), do: parse_list(tail, [])
  defp parse(<<?d::utf8, tail::bytes>>), do: parse_dictionary(tail, %{})
  defp parse(binary),                    do: parse_string(binary, [])

  defp parse_integer(<<?e::utf8, tail::bytes>>, acc),   do: {tail, List.to_integer(acc)}
  defp parse_integer(<<head::utf8, tail::bytes>>, acc), do: parse_integer(tail, acc ++ List.wrap(head))

  defp parse_string(<<?:::utf8, tail::bytes>>, acc) do
    length = List.to_integer(acc)

    # Extract the integer prefix that denotes the string's length
    <<string::bytes-size(length), rest::bytes>> = tail

    {rest, string}
  end

  defp parse_string(<<head::utf8, tail::bytes>>, acc) do
    parse_string(tail, acc ++ List.wrap(head))
  end

  defp parse_list(<<?e::utf8, tail::bytes>>, acc) do
    {tail, acc}
  end

  defp parse_list(binary, acc) do
    # Recursively decode each item in the list
    {val_rest, val} = parse(binary)

    parse_list(val_rest, acc ++ [val])
  end

  defp parse_dictionary(<<?e::utf8, tail::bytes>>, acc) do
    {tail, acc}
  end

  defp parse_dictionary(binary, acc) do
    # The key must be a string.
    {key_rest, key} = parse_string(binary, [])

    # Recursively decode each value
    {val_rest, val} = parse(key_rest)

    # Decode the key as an atom for convenience
    rest = Map.put(acc, String.to_atom(key), val)

    parse_dictionary(val_rest, rest)
  end

  defp unparse(integer) when is_integer(integer) do
    "i" <> Integer.to_string(integer) <> "e"
  end

  defp unparse(string) when is_binary(string) do
    (string |> byte_size |> Integer.to_string) <> ":" <> string
  end

  defp unparse(atom) when is_atom(atom) do
    atom |> Atom.to_string |> unparse
  end

  defp unparse(list) when is_list(list) do
    # Recursively encode each item in the list
    "l" <> (list |> Enum.map(&unparse/1) |> List.to_string) <> "e"
  end

  defp unparse(dictionary) when is_map(dictionary) do
    # Recursively encode each key and value and sort by key. Then, reduce the
    # dictionary into a string.
    encoded_dictionary =
      dictionary
      |> Enum.sort
      |> Enum.map(fn {k, v} ->
        (k |> unparse |> List.wrap) ++ (v |> unparse |> List.wrap)
      end)
      |> List.flatten
      |> List.foldr("", fn x, acc -> to_string(x) <> to_string(acc) end)

    "d" <> encoded_dictionary <> "e"
  end
end
