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
    |> decode_type
    # Separate the decoded binary from the accumulator
    |> elem(0)
  end

  defp decode_type(<<?i::utf8, rest::bytes>>), do: decode_integer(rest, [])
  defp decode_type(<<?l::utf8, rest::bytes>>), do: decode_list(rest, [])
  defp decode_type(<<?d::utf8, rest::bytes>>), do: decode_dict(rest, %{})
  defp decode_type(binary),                    do: decode_string(binary, [])

  defp decode_integer(<<?e::utf8, rest::bytes>>, acc) do
    acc =
      acc
      |> Enum.reverse
      |> List.to_integer
    {acc, rest}
  end

  defp decode_integer(<<head::utf8, rest::bytes>>, acc) do
    decode_integer(rest, [head | acc])
  end

  defp decode_string(<<?:::utf8, rest::bytes>>, acc) do
    size =
      acc
      |> Enum.reverse
      |> List.to_integer

    # Extract the integer prefix that denotes the string's length
    <<string::bytes-size(size), rest::bytes>> = rest

    {string, rest}
  end

  defp decode_string(<<head::utf8, rest::bytes>>, acc) do
    decode_string(rest, [head | acc])
  end

  defp decode_list(<<?e::utf8, rest::bytes>>, acc) do
    {Enum.reverse(acc), rest}
  end

  defp decode_list(binary, acc) do
    # Recursively decode each item in the list
    {val, val_rest} = decode_type(binary)

    decode_list(val_rest, [val | acc])
  end

  defp decode_dict(<<?e::utf8, rest::bytes>>, acc) do
    {acc, rest}
  end

  defp decode_dict(binary, acc) do
    # The key must be a string.
    {key, key_rest} = decode_string(binary, [])

    # Recursively decode each value
    {val, val_rest} = decode_type(key_rest)

    # Decode the key as an atom for convenience
    rest = Map.put(acc, String.to_atom(key), val)

    decode_dict(val_rest, rest)
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
    encode_type(data)
  end

  defp encode_type(integer) when is_integer(integer) do
    "i" <> Integer.to_string(integer) <> "e"
  end

  defp encode_type(string) when is_binary(string) do
    (string |> byte_size |> Integer.to_string) <> ":" <> string
  end

  defp encode_type(atom) when is_atom(atom) do
    atom |> Atom.to_string |> encode_type
  end

  defp encode_type(list) when is_list(list) do
    # Recursively encode each item in the list
    "l" <> (list |> Enum.map(&encode_type/1) |> List.to_string) <> "e"
  end

  defp encode_type(dict) when is_map(dict) do
    # Sort by key and recursively encode each key and value. Then, reduce the
    # dictionary into a string.
    dict =
      dict
      |> Enum.sort
      |> Enum.map(fn {k, v} -> encode_type(k) <> encode_type(v) end)
      |> Enum.reduce("", fn x, acc -> acc <> x end)

    "d" <> dict <> "e"
  end
end
