defmodule Trex.Server do
  @moduledoc false

  use GenServer

  alias Trex.Protocol
  alias Trex.Torrent
  require Logger

  @opts [:binary, active: 1]
  @timeout 2_000

  # Client -------------------------------------------------------------------

  @doc false
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  # Server -------------------------------------------------------------------

  def init(state) do
    socket =
      connect(state.ip, state.port)

    handshake(socket, state.handshake_msg)

    state =
      Map.merge(state, %{
        peer_state: :pre_handshake, # temporary
        socket: socket,             # TCP socket to send and receive messages
        next_sub_piece_index: 0
      })

    {:ok, state}
  end

  ## TCP =====================================================================

  def handle_info({:tcp, socket, data}, state) do
    {msgs, _} =
      Protocol.decode(data)

    # Loop through the messages to determine the peer's next state.
    state =
      loop_messages(msgs, state)

    Logger.debug(state.peer_state)

    next_msg =
      Protocol.encode(:keep_alive)

    # TODO: cleanup
    case state.peer_state do
      :we_choke ->
        next_msg =
          Protocol.encode(:interested)
      :me_choke_it_interest ->
        next_piece_index =
          Torrent.get_next_piece_index(state.torrent)

        next_sub_piece_index =
          state.next_sub_piece_index

        # Logger.debug(next_sub_piece_index)

        next_msg =
          Protocol.encode(:request, next_piece_index, next_sub_piece_index)
      # :me_interest_it_choke ->
        # TODO
      _ ->
        IO.puts "Unknown state: #{state.peer_state}"
        System.halt(0)
    end

    # IO.inspect "#{next_msg.type} message received."
    :gen_tcp.send(socket, next_msg)

    {:noreply, state}
  end

  # TODO: add in a timeout
  def handle_info({:error, reason}, state) do
    case reason do
      # :timeout ->
        # TODO: retry same peer?
      # :econnrefused ->
        # TODO: retry another peer?
      _ ->
        reason
    end

    {:noreply, state}
  end

  def handle_info({:tcp_passive, socket}, state) do
    # Logger.debug("The socket is in passive mode.")
    :inet.setopts(socket, [active: 1])
    # Logger.debug("The socket is in active mode.")

    {:noreply, state}
  end

  # TODO: add in a timeout
  def handle_info({:tcp_closed, _socket}, state) do
    Logger.debug("The socket is closed.")

    # Try another peer.

    {:noreply, state}
  end


  def handle_info({:tcp_error, reason}, state) do
    Logger.debug("A TCP error has occurred: #{reason}")

    # Try another peer.

    {:noreply, state}
  end

  # Helpers ------------------------------------------------------------------

  defp connect(ip, port) do
    {:ok, socket} =
      :gen_tcp.connect(ip, port, @opts, @timeout)

    Logger.debug("#{to_dotted_ip(ip)}:#{port} connected.")

    socket
  end

  defp handshake(socket, msg) do
    :gen_tcp.send(socket, msg)
  end

  defp loop_messages([msg | msgs], state) do
    # unless msg.type == :keep_alive do
      Logger.debug(msg.type)
    # end

    case msg.type do
      :handshake ->
        state = %{state |
          peer_state: :we_choke
        }
      :keep_alive ->
        :ok
        # reset keep-alive timeout
      :choke ->
        state = %{state |
          peer_state: :we_choke
        }
        # stop leeching
      :unchoke ->
        state = %{state |
          peer_state: :me_choke_it_interest
        }
        # start/continue leeching
      :interested ->
        :ok
        # start seeding
      :not_interested ->
        :ok
        # stop seeding
      :have ->
        :ok
        # mark pieces that the peer has
      :bitfield ->
        :ok
        # mark pieces that the peer has
      # :request ->
        # TODO
      :piece ->
        Torrent.put_sub_piece(state.torrent, msg.piece_index, msg.block_offset, msg.block)
        state = %{state |
          # next_sub_piece_index: state.next_sub_piece_index + 1
          next_sub_piece_index: msg.block_offset + 1
        }
      # :cancel ->
        # TODO
      # :port ->
        # TODO
    end

    loop_messages(msgs, state)
  end

  defp loop_messages(_, state) do
    state
  end

  defp to_dotted_ip(ip) do
    ip
    |> Tuple.to_list
    |> Enum.join(".")
  end

  def request_next_piece(piece_len, state) do
    Protocol.encode(:request, state.current_piece, state.current_block)
  end

  def request_next_block do
    :ok
  end
end
