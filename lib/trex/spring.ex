defmodule Trex.Spring do
  @moduledoc """
  Supervise torrents.
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_torrent(binary) do
    # NOTE: pid or module?
    Supervisor.start_child(__MODULE__, [binary])
  end

  def init(_) do
    # TODO: handle errors
    # Create the listening socket for all torrents to connect to.
    {:ok, lsocket} =
      :gen_tcp.listen(Application.get_env(:trex, :port), [:binary, active: 1])

    children = [
      worker(Trex.Torrent, [lsocket], restart: :transient, debug: [:trace])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
