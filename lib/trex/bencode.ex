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
    |> elem(0)
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

  defp parse_integer(<<?e::utf8, tail::bytes>>, acc) do
    acc =
      acc
      |> Enum.reverse
      |> List.to_integer
    {acc, tail}
  end
  defp parse_integer(<<head::utf8, tail::bytes>>, acc) do
    parse_integer(tail, [head | acc])
  end

  defp parse_string(<<?:::utf8, tail::bytes>>, acc) do
    length =
      acc
      |> Enum.reverse
      |> List.to_integer

    # Extract the integer prefix that denotes the string's length
    <<string::bytes-size(length), rest::bytes>> = tail

    {string, rest}
  end

  defp parse_string(<<head::utf8, tail::bytes>>, acc) do
    parse_string(tail, [head | acc])
  end

  defp parse_list(<<?e::utf8, tail::bytes>>, acc) do
    {Enum.reverse(acc), tail}
  end

  defp parse_list(binary, acc) do
    # Recursively decode each item in the list
    {val, val_rest} = parse(binary)

    parse_list(val_rest, [val | acc])
  end

  defp parse_dictionary(<<?e::utf8, tail::bytes>>, acc) do
    {acc, tail}
  end

  defp parse_dictionary(binary, acc) do
    # The key must be a string.
    {key, key_rest} = parse_string(binary, [])

    # Recursively decode each value
    {val, val_rest} = parse(key_rest)

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
    # Sort by key and recursively encode each key and value. Then, reduce the
    # dictionary into a string.
    dictionary =
      dictionary
      |> Enum.sort
      |> Enum.map(fn {k, v} ->
        unparse(k) <> unparse(v)
      end)
      |> Enum.reduce("", fn x, acc -> acc <> x end)

    "d" <> dictionary <> "e"
  end
end
