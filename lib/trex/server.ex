defmodule Trex.Server do
  @moduledoc false

  use GenServer

  alias Trex.Protocol
  alias Trex.Torrent
  require Logger

  @opts [:binary, active: 1]
  @timeout 2_000
  @interested_interval 5_000
  @keep_alive_interval 30_000

  # Client -------------------------------------------------------------------

  @doc false
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  # Server -------------------------------------------------------------------

  def init(state) do
    timer =
      :erlang.start_timer(@interested_interval, self(), :send_message)

    socket =
      connect(state.ip, state.port)

    handshake(socket, state.handshake_msg)

    state =
      Map.merge(state, %{
        next_sub_piece_index: 0,
        peer_state: :pre_handshake, # temporary
        socket: socket,             # TCP socket to send and receive messages
        timer: timer
      })

    {:ok, state}
  end


  def handle_info({:timeout, timer, :send_message}, state) do
    :erlang.cancel_timer(timer)

    socket =
      state.socket

    case state.peer_state do
      :we_choke ->
        msg =
          Protocol.encode(:interested)
        :gen_tcp.send(socket, msg)

        timer =
          :erlang.start_timer(@interested_interval, self(), :send_message)

        Logger.debug "Sent interested."
      :we_interest ->
        :ok
      :me_choke_it_interest ->
        msg =
          Protocol.encode(:keep_alive)
        :gen_tcp.send(socket, msg)

        timer =
          :erlang.start_timer(@keep_alive_interval, self(), :send_message)

        Logger.debug "Sent keep-alive."
      :me_interest_it_choke ->
        :ok
      _ ->
        timer =
          :erlang.start_timer(@keep_alive_interval, self(), :send_message)
    end

    state =
      %{state | timer: timer}

    {:noreply, state}
  end

  ## TCP =====================================================================

  def handle_info({:tcp, _socket, data}, state) do
    {msgs, _} =
      Protocol.decode(data)

    # Loop through the messages to determine the peer's next state.
    state =
      loop_messages(msgs, state)

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
    unless msg.type == :keep_alive do
      Logger.debug(msg.type)
    end

    peer_state = state.peer_state

    case msg.type do
      :handshake ->
        if peer_state == :pre_handshake do
          state =
            %{state | peer_state: :we_choke}
        end

      # reset keep-alive timeout
      # :keep_alive ->

      # stop leeching
      :choke ->
        state =
          case peer_state do
            :we_interest ->
              %{state | peer_state: :me_interest_it_choke}
            :me_interest_it_choke ->
              %{state | peer_state: :we_choke}
          end

      # start/continue leeching
      :unchoke ->
        state =
          case peer_state do
            :we_choke ->
              %{state | peer_state: :me_choke_it_interest}
            :me_interest_it_choke ->
              %{state | peer_state: :we_interest}
          end

        next_piece_index =
          Torrent.get_next_piece_index(state.torrent)

        # request sub-pieces in order
        next_sub_piece_index = 0

        msg =
          Protocol.encode(:request, next_piece_index, next_sub_piece_index)
        :gen_tcp.send(state.socket, msg)
        Logger.debug "Sent request for sub-piece #{next_sub_piece_index} for piece #{next_piece_index}."

        state =
          %{state | next_sub_piece_index: next_sub_piece_index + 1}

      # start seeding
      # :interested ->

      # stop seeding
      # :not_interested ->

      # mark pieces that the peer has
      :have ->
        :ok

      # mark pieces that the peer has
      :bitfield ->
        first = <<a, b, c, d>> <> <<rest::binary>> = msg.bitfield
        IO.inspect first

      # TODO
      # :request ->

      :piece ->
        Torrent.put_sub_piece(
          state.torrent,
          msg.piece_index,
          msg.block_offset,
          msg.block
        )

        IO.puts "piece index and sub-piece index"
        IO.inspect msg.piece_index
        IO.inspect msg.block_offset

        next_piece_index =
          Torrent.get_next_piece_index(state.torrent)

        next_sub_piece_index =
          if msg.block_offset + 1 < 32  do
            msg.block_offset + 1
          else
            0
          end

        msg =
          Protocol.encode(
            :request,
            next_piece_index,
            next_sub_piece_index
          )
        :gen_tcp.send(state.socket, msg)

        Logger.debug "Sent request for sub-piece #{next_sub_piece_index} for piece #{next_piece_index}."

        state =
          %{state | next_sub_piece_index: next_sub_piece_index}

      # TODO
      # :cancel ->

      # TODO
      # :port ->

      type ->
        unless msg.type == :keep_alive do
          Logger.debug "Did not handle message type #{type}."
        end
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

  # defp send_message(socket, msg) do
  #   :gen_tcp.send(socket, msg)
  # end
end
