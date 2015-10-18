defmodule Trex.Peer.Messages do
  @moduledoc """
  Peer protocol messages decoder and encoder.
  """

  require Logger

  @block_length 16384 # 2^(14)

  @handshake_len  19
  @keep_alive_len 0
  @no_payload_len 1  # length of messages with no payload
  @have_len       5
  @request_len    13
  @piece_len      9
  @cancel_len     13

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
  Decode peer protocol messages return a map of data and any remaining message
  fragments.

  ## Examples
  """
  def decode(binary) do
    decode_type(binary)
  end

  # defp decode(_, acc) do
  #   acc
  # end

  defp decode_type(<<
    @handshake_len,
    "BitTorrent protocol",
    reserved::bytes-size(8),
    info_hash::bytes-size(20),
    peer_id::bytes-size(20),
    rest::bytes
  >>) do
    {%{
      type: :handshake,
      reserved: reserved,
      info_hash: info_hash,
      peer_id: peer_id
    }, rest}
  end

  defp decode_type(<<@keep_alive_len::size(32), rest::bytes>>) do
    {%{type: :keep_alive}, rest}
  end

  defp decode_type(<<@no_payload_len::size(32), @choke_id, rest::bytes>>) do
    {%{type: :choke}, rest}
  end

  defp decode_type(<<@no_payload_len::size(32), @unchoke_id, rest::bytes>>) do
    {%{type: :unchoke}, rest}
  end

  defp decode_type(<<
    @no_payload_len::size(32),
    @interested_id,
    rest::bytes
  >>) do
    {%{type: :interested}, rest}
  end

  defp decode_type(<<
    @no_payload_len::size(32),
    @not_interested_id,
    rest::bytes
  >>) do
    {%{type: :not_interested}, rest}
  end

  defp decode_type(<<
    @have_len::size(32),
    @have_id,
    piece_index::size(32),
    rest::bytes
  >>) do
    {%{type: :have, piece_index: piece_index}, rest}
  end

  defp decode_type(<<length::size(32), @bitfield_id, rest::bytes>>) do
    <<bitfield::bytes-size(length), rest::bytes>> = rest
    {%{type: :bitfield, bitfield: bitfield}, rest}
  end

  # TODO: DRY
  defp decode_type(<<
    @request_len::size(32),
    @request_id,
    piece_index::size(32),
    block_offset::size(32),
    block_length::size(32),
    rest::bytes
  >>) do
    {%{
      type: :request,
      piece_index: piece_index,
      block_offset: block_offset,
      block_length: block_length
    }, rest}
  end

  defp decode_type(<<
    @piece_len::size(32),
    @piece_id,
    piece_index::size(32),
    block_offset::size(32),
    block::size(32),
    rest::bytes
  >>) do
    {%{
      type: :piece,
      piece_index: piece_index,
      block_offset: block_offset,
      block: block
    }, rest}
  end

  defp decode_type(<<
    @cancel_len::size(32),
    @cancel_id,
    piece_index::size(32),
    block_offset::size(32),
    block_length::size(32),
    rest::bytes
  >>) do
    {%{
      type: :cancel,
      piece_index: piece_index,
      block_offset: block_offset,
      block_length: block_length
    }, rest}
  end

  defp decode_type(binary) do
    binary
  end

  @doc """
  Encode a peer protocol binary of type `type`.
  """
  def encode(type) do
    encode_type(type)
  end

  defp encode_type(:keep_alive) do
    <<0::size(32)>>
  end

  defp encode_type(:choke) do
    <<1::size(32)>> <> <<0>>
  end

  defp encode_type(:unchoke) do
    <<1::size(32)>> <> <<1>>
  end

  defp encode_type(:interested) do
    <<1::size(32)>> <> <<2>>
  end

  defp encode_type(:not_interested) do
    <<1::size(32)>> <> <<3>>
  end

  @doc """
  Encode a map of data into a peer protocol binary of type `type`.
  """
  def encode(type, data) do
    encode_type(type, data)
  end

  defp encode_type(:handshake, reserved, info_hash, peer_id) do
    <<
      19,
      "BitTorrent protocol",
      reserved::bytes-size(8),
      info_hash::bytes-size(20),
      peer_id::bytes-size(20)
    >>
  end

  defp encode_type(:have, piece_index) do
    <<5::size(32)>> <> <<4>> <> <<piece_index::size(32)>>
  end

  defp encode_type(:bitfield, bitfield) do
    message = <<5>> <> bitfield
    <<byte_size(message)::size(32)>> <> message
  end

  defp encode_type(
    :request,
    piece_index,
    block_offset,
    block_length
  ) do
    <<13::size(32)>> <> <<6>> <> <<
      piece_index::size(32),
      block_offset::size(32),
      block_length::size(32)
    >>
  end

  defp encode_type(:piece, piece_index, block_offset, piece) do
    message =
      <<7>>
      <> <<piece_index::size(32), block_offset::size(32)>>
      <> piece
    <<byte_size(message)::size(32)>> <> messsage
  end

  defp encode_type(
    :cancel,
    piece_index,
    block_offset,
    block_length
  ) do
    <<13::size(32)>> <> <<6>> <> <<
      piece_index::size(32),
      block_offset::size(32),
      block_length::size(32)
    >>
  end
end
