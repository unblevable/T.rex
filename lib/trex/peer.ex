defmodule Trex.Peer do
  @moduledoc """
  Handle peer state and single peer-to-peer (or client-to-peer) communication.

  ## Events

  +   me_choke
  +   me_interest
  +   it_choke
  +   it_interest

  +   have
  +   bitfield
  +   request
  +   piece
  +   cancel

  ## States
  Each state is a combination of "me_choke" or "me_interest" and "it_choke" or
  "it_interest". The Tarzan-like grammar is for brevity:

  +   we_choke (initial state)
  +   we_interest
  +   me_choke_it_interest
  +   me_interest_it_choke
  """

  @behaviour :gen_fsm

  require Logger

  # Client API ---------------------------------------------------------------

  def start_link(peer_socket, peer_id) do
    :gen_fsm.start_link(__MODULE__, [peer_socket], name: peer_id)
  end

  # Server callbacks ---------------------------------------------------------

  def init(peer) do
    {:ok, :we_choke, peer}
  end

  ## Events ------------------------------------------------------------------

  @doc """
  This client is choking the given peer and vice-versa.
  """
  def we_choke(:me_interest, state) do
    {:next_state, :me_interest_it_choke, state}
  end

  def we_choke(:it_interest, state) do
    {:next_state, :me_choke_it_interest, state}
  end

  @doc """
  This client is interested in the given peer and vice-versa.
  """
  def we_interest(:me_choke, state) do
    {:next_state, :me_choke_it_interest, state}
  end

  def we_interest(:it_choke, state) do
    {:next_state, :me_interest_it_choke, state}

  end

  @doc """
  This client is choking the given peer, but the peer is interested in the
  client.
  """
  def me_choke_it_interest(:me_interest, state) do
    {:next_state, :we_interest, state}
  end

  def me_choke_it_interest(:it_choke, state) do
    {:next_state, :we_choke, state}
  end

  @doc """
  This client is interested in the given peer, but the peer is choking the
  client.
  """
  def me_interest_it_choke(:me_choke, state) do
    {:next_state, :we_choke, state}
  end

  def me_interest_it_choke(:it_interest, state) do
    {:next_state, :we_interest, state}
  end

  ## Placeholder =============================================================

  @doc false
  def terminate(_reason, _state, _data) do
    :ok
  end

  @doc false
  def code_change(_old, state, data, _extra) do
    {:ok, state, data}
  end

  ## Helper ==================================================================
  defp loop do
  end
end
