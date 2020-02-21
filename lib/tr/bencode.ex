defmodule Tr.Bencode do
  # TODO: Follow conventions of error handling, i.e. { :ok, data }, Tr.Bencode.encode!, etc
  @moduledoc """
  Bencode decoder and encoder.
  """

  @doc """
  Decode bencode types into corresponding Elixir data types.

  ## Examples

    iex> Tr.Bencode.decode("4:spam")
    "spam"

    iex> Tr.Bencode.decode("i3e")
    3

    iex> Tr.Bencode.decode("l4:spam4:eggse")
    ["spam", "eggs"]

    iex> Tr.Bencode.decode("d3:cow3:moo4:spam4:eggse")
    %{"cow" => "moo", "spam" => "eggs"}

    iex> Tr.Bencode.decode("d4:spaml1:a1:bee")
    %{"spam" => ["a", "b"]}

  """
  def decode(binary) do
    binary
    |> decode_type
    # From the returned tuple, get the decoded binary and ignore the rest of the un-decoded binary
    |> elem(0)
  end

  @doc """
  Encode Elixir data types into corresponding bencode types. Returns an IO list (potentially
  nested).

  ## Examples

    iex> Tr.Bencode.encode(:eggs)
    ["4", ":", "eggs"]

    iex> Tr.Bencode.encode("spam")
    ["4", ":", "spam"]

    iex> Tr.Bencode.encode(3)
    ["i", "3", "e"]

    iex> Tr.Bencode.encode(["spam", "eggs"])
    [
      "l",
      [
        ["4", ":", "spam"],
        ["4", ":", "eggs"]
      ],
      "e",
    ]

    iex> Tr.Bencode.encode(%{"cow" => "moo", "spam" => "eggs"})
    [
      "d",
      [
        [
          ["3", ":", "cow"],
          ["3", ":", "moo"],
        ],
        [
          ["4", ":", "spam"],
          ["4", ":", "eggs"],
        ],
      ],
      "e",
    ]

  """
  def encode(data) do
    encode_type(data)
  end

  defp decode_type(<<?i::utf8, rest::bytes>>), do: decode_integer(rest, [])
  defp decode_type(<<?l::utf8, rest::bytes>>), do: decode_list(rest, [])
  defp decode_type(<<?d::utf8, rest::bytes>>), do: decode_dictionary(rest, %{})
  defp decode_type(binary), do: decode_string(binary, [])

  defp decode_integer(<<?e::utf8, rest::bytes>>, acc) do
    {
      acc
      |> Enum.reverse()
      |> List.to_integer(),
      rest
    }
  end

  # NOTE: The number (head) is encoded in ascii
  defp decode_integer(<<head::utf8, rest::bytes>>, acc) do
    decode_integer(rest, [head | acc])
  end

  defp decode_list(<<?e::utf8, rest::bytes>>, acc) do
    {Enum.reverse(acc), rest}
  end

  defp decode_list(binary, acc) do
    # Recursively decode each item in the list
    {val, val_rest} = decode_type(binary)

    decode_list(val_rest, [val | acc])
  end

  defp decode_dictionary(<<?e::utf8, rest::bytes>>, acc) do
    {acc, rest}
  end

  defp decode_dictionary(binary, acc) do
    # The key must be a string
    {key, key_rest} = decode_string(binary, [])

    # Recursively decode each value
    {val, val_rest} = decode_type(key_rest)

    # TODO: We'd ideally decode the key as an atom for convenience, but this would lead to memory
    # problems with malicious input
    rest = Map.put(acc, key, val)

    decode_dictionary(val_rest, rest)
  end

  defp decode_string(<<?:::utf8, rest::bytes>>, acc) do
    size =
      acc
      |> Enum.reverse()
      |> List.to_integer()

    # Extract the integer prefix that denote's the string's length
    <<string::bytes-size(size), rest::bytes>> = rest

    {string, rest}
  end

  # NOTE: "Strings" can be UTF-8 encoded strings or raw byte arrays
  defp decode_string(<<head::utf8, rest::bytes>>, acc) do
    decode_string(rest, [head | acc])
  end

  defp encode_type(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> encode_type
  end

  defp encode_type(string) when is_binary(string) do
    [
      string
      |> byte_size
      |> Integer.to_string(),
      ":",
      string
    ]
  end

  defp encode_type(integer) when is_integer(integer) do
    ["i", Integer.to_string(integer), "e"]
  end

  defp encode_type(list) when is_list(list) do
    # Recursively encode each item in the list
    ["l", Enum.map(list, &encode_type/1), "e"]
  end

  defp encode_type(dictionary) when is_map(dictionary) do
    # Sort by key and recursively encode each key and value. Then, reduce the dictionary into a
    # string
    [
      "d",
      dictionary
      |> Enum.sort()
      |> Enum.map(fn {k, v} -> [encode_type(k), encode_type(v)] end)
      |> Enum.reduce(fn x, acc -> [acc, x] end),
      "e"
    ]
  end
end
