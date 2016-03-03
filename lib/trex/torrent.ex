defmodule Trex.Torrent do
  @moduledoc """
  Manage torrent lifespan.
  """

  use GenServer

  alias Trex.Bencode
  alias Trex.Protocol
  alias Trex.Swarm
  alias Trex.Tracker
  require Logger

  @piece_hash_size 20

  # TODO: move to config
  @sub_piece_size 16384 # 2^14

  @timeout 5_000

  # Client -------------------------------------------------------------------

  @doc false
  def start_link(lsocket, binary) do
    GenServer.start_link(__MODULE__, [lsocket, binary], timeout: @timeout)
  end

  @doc """
  """
  def get_next_piece_index(pid) do
    GenServer.call(pid, :get_next_piece_index)
  end

  @doc """
  """
  def get_next_sub_piece_index(pid) do
    GenServer.call(pid, :get_next_sub_piece_index)
  end

  @doc """
  """
  def put_sub_piece(pid, piece_index, sub_piece_index, sub_piece) do
    GenServer.cast(pid, {:put_sub_piece, piece_index, sub_piece_index, sub_piece})
  end

  # Server -------------------------------------------------------------------

  def init([lsocket, binary]) do

    ## Tracker communication

    # TODO: optional keys
    # TODO: multiple-file torrents
    # NOTE: should this be init?
    %{
      announce: _announce,
      info: info = %{
        "piece length": piece_length,
        pieces: pieces,
        name: _name,
        length: length
      }
    } = file_info =
      Bencode.decode(binary)

    info_hash =
      :crypto.hash(:sha, Bencode.encode(info))

    client_id =
      Application.get_env(:trex, :client_id)

    # TODO: optional keys
    # TODO: BEP 23
    request_params = %{
      compact: 1,
      downloaded: 0,
      event: "started",
      info_hash: info_hash,
      # ip: "127.0.0.1",
      left: length,
      # TODO: move elsewhere
      peer_id: client_id,
      port: Application.get_env(:trex, :port),
      uploaded: 0
    }

    request_url =
      file_info.announce <> "?" <> URI.encode_query(request_params)

    # TODO: timeout or error handling
    %{
      interval: _interval,
      peers: peers_binary
    } = tracker_info = Tracker.request(request_url)

    # TODO: use ETS instead of tuples?
    ## Piece selection

    piece_size =
      piece_length * 8;
    num_pieces =
      div(byte_size(pieces), @piece_hash_size)

    # The piece length might not be evenly divisible by the sub-piece length.
    num_sub_pieces =
      (piece_length / @sub_piece_size)
      |> Float.ceil
      |> trunc

    # use ETS to store sub-pieces sequentially in memory
    piece_buffer = :ets.new(:piece, [:ordered_set])

    # Select a random first piece.
    next_piece_index =
      Enum.random(0..(num_pieces - 1));

    next_sub_piece_index = 0

    ## Swarm

    peer_state = %{
      torrent: self(),
      lsocket: lsocket,
      piece_length: piece_length,
      pieces: pieces,
    }

    swarm =
      start_swarm(peers_binary, info_hash, client_id, peer_state)

    ## Upkeep

    state = %{
      num_pieces: num_pieces,
      num_sub_pieces: num_sub_pieces,
      next_piece_index: next_piece_index,
      next_sub_piece_index: next_sub_piece_index,
      piece_buffer: piece_buffer,

      file_info: file_info,
      swarm: swarm,
      tracker_info: tracker_info,
    }

    {:ok, state}
  end

  ## Callbacks ===============================================================

  def handle_call(:get_next_piece_index, _from, state) do
    # if the piece buffer is new
    next_piece_index =
      if state.piece_buffer == {} do
      # select next rarest piece
      0
      else
        state.next_piece_index
      end

    state =
      %{state | next_piece_index: next_piece_index}

    {:reply, next_piece_index, state}
  end

  # TODO
  def handle_call(:get_next_sub_piece_index, _from, state) do
    sub_piece_index =
      state.sub_piece_index

    {:reply, sub_piece_index, state}
  end

  def handle_cast({:put_sub_piece, _piece_index, sub_piece_index, sub_piece}, state) do
    piece_buffer =
      state.piece_buffer

    if sub_piece_index < state.num_sub_pieces do
      Logger.debug "sub piece index: #{sub_piece_index}"
      :ets.insert(piece_buffer, {sub_piece_index, sub_piece})
    else
      IO.inspect :ets.tab2list(piece_buffer)
      # clear the piece buffer
      :ets.delete_all_objects(piece_buffer)

      # move onto the next piece
      # TODO: use get_next_piece_index
      state =
        %{state | next_piece_index: state.next_piece_index + 1}
    end

    {:noreply, state}
  end

  # Helpers ------------------------------------------------------------------

  defp start_swarm(peers_binary, info_hash, client_id, peer_state) do
    {:ok, swarm} =
      Supervisor.start_link(Trex.Swarm, [])

    handshake_msg =
      Protocol.encode(:handshake, <<0::size(64)>>, info_hash, client_id)

    peer_state =
      Map.put(peer_state, :handshake_msg, handshake_msg)

    # NOTE: use proc_lib?
    # Call spawn_link() to prevent a deadlock in init(), since each peer will
    # block to wait for messages.
    spawn_link(fn ->
      start_peers(swarm, peers_binary, peer_state)
    end)

    swarm
  end

  defp start_peers(swarm, peers_binary, peer_state) do
    peers_binary
    |> parse_peers_binary
    |> Enum.take_random(Application.get_env(:trex, :num_peers))
    |> Enum.map(fn {ip, port} ->
      peer_state =
        Map.merge(peer_state, %{
          ip: ip,
          port: port
        })

      Swarm.start_peer(swarm, peer_state)
    end)
  end

  # The binary contains a series of 6 bytes per peer.
  #
  # Each of the first 4 bytes hold an octet of the peer's ip address. The last
  # 2 bytes hold the peer's port number.
  defp parse_peers_binary(binary) do
    parse_peers_binary(binary, [])
  end

  defp parse_peers_binary(<<a, b, c, d, port::size(16), rest::bytes>>, acc) do
    parse_peers_binary(rest, [{{a, b, c, d}, port} | acc])
  end

  defp parse_peers_binary(_, acc) do
    acc
  end
end
