defmodule Trex.Messages do
  @moduledoc """
  Manage peer-to-peer BitTorrent messages.
  """

  @doc "keep-alive"
  def get(<<0::size(32)>>) do
    IO.puts "keep-alive"
  end

  @doc "choke"
  def get(<<1::size(32)>> <> <<1>>) do
    IO.puts "choke"
  end

  @doc "unchoke"
  def get(<<1::size(32)>> <> <<2>>) do
    IO.puts "unchoke"
  end

  @doc "interested"
  def get(<<1::size(32)>> <> <<3>>) do
    IO.puts "interested"
  end

  @doc "not interested"
  def get(<<1::size(32)>> <> <<4>>) do
    IO.puts "not interested"
  end

  @doc "have"
  def get(<<5::size(32)>> <> <<4>> <> <<index::size(32)>>) do
    IO.puts "have"
  end

  @doc "bitfield"
  def get(<<len::size(32)>> <> <<5>> <> <<bitfield::bytes>>) do
    IO.puts "bitfield"
    Agent.update(:peer, fn state -> Map.put(state, :bitfield, bitfield) end)
    IO.inspect bitfield
  end

  @doc "request"
  def get(<<13::size(32)>> <> <<6>> <> <<index::size(32), begin::size(32), length::size(32)>>) do
    IO.puts "request"
  end

  @doc "piece (a _block_ is a sub-piece)"
  def get(<<9::size(32)>> <> <<7>> <> <<index::size(32), begin::size(32), block::size(32)>>) do
    IO.puts "piece"
  end

  @doc "cancel"
  def get(<<13::size(32)>> <> <<8>> <> <<index::size(32), begin::size(32), block::size(32)>>) do
    IO.puts "cancel"
  end

  @doc "port (newer versions of the Mainline)"
  def get(<<3::size(32)>> <> <<9>> <> <<listen_port::size(16)>>) do
    IO.puts "port"
  end

  def get("") do
    IO.puts "blank data"
  end

  def start(socket) do
    IO.puts "Peer state started"
    Agent.start(fn -> %{} end, name: :peer)
  end

  def send_keep_alive(socket) do
    :gen_tcp.send(socket, <<0::size(32)>>)
  end
end
