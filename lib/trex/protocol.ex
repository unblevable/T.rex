defmodule Trex.Protocol do
  @moduledoc """
  Peer protocol message decoder and encoder.
  """

  require Logger

  @block_length 16384 # 2^(14)

  @protocol_string_len 19
  @keep_alive_len      0
  @no_payload_len      1  # length of messages with no payload
  @have_len            5
  @request_len         13
  @cancel_len          13

  @choke_id          0
  @unchoke_id        1
  @interested_id     2
  @not_interested_id 3
  @have_id           4
  @bitfield_id       5
  @request_id        6
  @piece_id          7
  @cancel_id         8

  @doc """
  Decode a binary of peer protocol messages and return a list of messages and
  any remaining bytes.

  ## Examples
  """
  def decode(binary) do
    decode_type(binary, [])
  end

  defp decode_type(<<
    @protocol_string_len,
    "BitTorrent protocol",
    reserved::bytes-size(8),
    info_hash::bytes-size(20),
    peer_id::bytes-size(20),
    rest::bytes
  >>, acc) do
    decode_type(rest, [%{
      type: :handshake,
      reserved: reserved,
      info_hash: info_hash,
      peer_id: peer_id
    } | acc])
  end

  defp decode_type(<<@keep_alive_len::size(32), rest::bytes>>, acc) do
    decode_type(rest, [%{type: :keep_alive} | acc])
  end

  defp decode_type(
    <<@no_payload_len::size(32), @choke_id, rest::bytes>>,
    acc
  ) do
    decode_type(rest, [%{type: :choke} | acc])
  end

  defp decode_type(
    <<@no_payload_len::size(32), @unchoke_id, rest::bytes>>,
    acc
  ) do
    decode_type(rest, [%{type: :unchoke} | acc])
  end

  defp decode_type(
    <<@no_payload_len::size(32), @interested_id, rest::bytes>>,
    acc
  ) do
    decode_type(rest, [%{type: :interested} | acc])
  end

  defp decode_type(
    <<@no_payload_len::size(32), @not_interested_id, rest::bytes>>,
    acc
  ) do
    decode_type(rest, [%{type: :not_interested} | acc])
  end

  defp decode_type(
    <<@have_len::size(32), @have_id, piece_index::size(32), rest::bytes>>,
    acc
  ) do
    decode_type(rest, [%{type: :have, piece_index: piece_index} | acc])
  end

  # NOTE: A bitfield of the wrong length is considered an error.
  defp decode_type(<<length::size(32), @bitfield_id, rest::bytes>>, acc) do
    # Subtract the id length.
    length = length - 1

    <<bitfield::bytes-size(length), rest::bytes>> = rest
    decode_type(rest, [%{type: :bitfield, bitfield: bitfield} | acc])
  end

  # TODO: DRY
  defp decode_type(<<
    @request_len::size(32),
    @request_id,
    piece_index::size(32),
    block_offset::size(32),
    block_length::size(32),
    rest::bytes
  >>, acc) do
    decode_type(rest, [%{
      type: :request,
      piece_index: piece_index,
      block_offset: block_offset,
      block_length: block_length
    } | acc])
  end

  defp decode_type(<<
    _length::size(32),
    @piece_id,
    piece_index::size(32),
    block_offset::size(32),
    block::size(32),
    rest::bytes
  >>, acc) do
    decode_type(rest, [%{
      type: :piece,
      piece_index: piece_index,
      block_offset: block_offset,
      block: block
    } | acc])
  end

  defp decode_type(<<
    @cancel_len::size(32),
    @cancel_id,
    piece_index::size(32),
    block_offset::size(32),
    block_length::size(32),
    rest::bytes
  >>, acc) do
    decode_type(rest, [%{
      type: :cancel,
      piece_index: piece_index,
      block_offset: block_offset,
      block_length: block_length
    } | acc])
  end

  # Return the list of messages and any remaining bytes.
  defp decode_type(rest, acc) do
    {Enum.reverse(acc), rest}
  end


  @doc """
  Encode a given type and associated data into a peer protocol binary.

  ## Examples
  """
  def encode(:keep_alive) do
    <<@keep_alive_len::size(32)>>
  end

  def encode(:choke) do
    <<@no_payload_len::size(32), @choke_id>>
  end

  def encode(:unchoke) do
    <<@no_payload_len::size(32), @unchoke_id>>
  end

  def encode(:interested) do
    <<@no_payload_len::size(32), @interested_id>>
  end

  def encode(:not_interested) do
    <<@no_payload_len::size(32), @not_interested_id>>
  end

  def encode(:have, piece_index) do
    <<@have_len::size(32), @have_id, piece_index::size(32)>>
  end

  def encode(:bitfield, bitfield) do
    message = <<@bitfield_id>> <> bitfield
    <<byte_size(message)::size(32)>> <> message
  end

  def encode(:handshake, reserved, info_hash, peer_id) do
    <<
      @protocol_string_len,
      "BitTorrent protocol",
      reserved::bytes-size(8),
      info_hash::bytes-size(20),
      peer_id::bytes-size(20)
    >>
  end

  def encode(
    :request,
    piece_index,
    block_offset,
    block_length
  ) do
    <<
      @request_len::size(32),
      @request_id,
      piece_index::size(32),
      block_offset::size(32),
      block_length::size(32)
    >>
  end

  def encode(:piece, piece_index, block_offset, piece) do
    message = <<@piece_id, piece_index::size(32), block_offset::size(32)>>
      <> piece
    <<byte_size(message)::size(32)>> <> message
  end

  def encode(
    :cancel,
    piece_index,
    block_offset,
    block_length
  ) do
    <<
      @cancel_len::size(32),
      @cancel_id,
      piece_index::size(32),
      block_offset::size(32),
      block_length::size(32)
    >>
  end
end
