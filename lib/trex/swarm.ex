defmodule Trex.Swarm do
  @moduledoc """
  Supervise peer connections.
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def start_peer(supervisor, ip, port, lsocket, handshake_msg) do
    Supervisor.start_child(supervisor, [ip, port, lsocket, handshake_msg])
  end

  def init(_) do
    children = [
      # worker(Trex.Peer, [])
      worker(Trex.Server, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  # defp loop(socket, data) do
  #   case Protocol.decode(data) do
  #     {[], _} ->
  #       Logger.debug "No message received."
  #       send_message(socket, :keep_alive)
  #     {messages, rest} ->
  #       Enum.each(messages, fn %{type: type} = message ->
  #         IO.inspect message
  #         case type do
  #           :handshake ->
  #             Logger.debug "Handshake message received."
  #             send_message(socket, :interested)
  #           :keep_alive ->
  #             Logger.debug "Keep alive message received."
  #             send_message(socket, :interested)
  #           :unchoke ->
  #             Logger.debug "Unchoke message received."
  #             send_message(socket, :keep_alive)
  #           _ ->
  #             Logger.debug "Other message received."
  #             send_message(socket, :keep_alive)
  #             IO.inspect messages
  #         end
  #       end)
  #   end
  # end
  #
  # defp send_message(socket, type) do
  #   message  = Protocol.encode(type)
  #   # :inet.setopts(socket, [active: :once])
  #   :gen_tcp.send(socket, message)
  #
  #   receive do
  #     {:tcp, socket, data} ->
  #       loop(socket, data)
  #     _ ->
  #       Logger.debug "Error"
  #   after
  #     @timeout ->
  #       Logger.debug("Peer timed out.")
  #       loop(socket, message)
  #   end
  # end

  # defp loop_through_messages(messages) do
  #   loop_through_messages(messages, [])
  # end
  #
  # defp loop_through_messages([head | tail], acc) do
  # end
  #
  # defp loop_through_messages(_, acc) do
  # end
end
