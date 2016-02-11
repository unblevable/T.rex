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

  # Client -------------------------------------------------------------------

  # TODO: correctly pass in peer id
  def start_link(peer) do
    :gen_fsm.start_link(__MODULE__, [peer], [])
  end

  ## Events ==================================================================

  def me_choke() do
    :gen_fsm.send_event(__MODULE__, :me_choke)
  end

  def me_interest() do
    :gen_fsm.send_event(__MODULE__, :me_interest)
  end

  def it_choke() do
    :gen_fsm.send_event(__MODULE__, :it_choke)
  end

  def it_interest() do
    :gen_fsm.send_event(__MODULE__, :it_interest)
  end

  # Server -------------------------------------------------------------------

  def init(peer) do
    {:ok, :we_choke, peer}
  end

  ## States ==================================================================

  @doc """
  This client is choking the given peer and vice-versa.
  """
  def we_choke(:me_interest, state) do
    # NOTE: (Temporary) Client immediately changes from choking to interested
    # state.
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

  def we_interest(:have, state) do
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

  ## Callbacks ===============================================================

  @doc false
  def handle_event(event, state_name, state_data) do
    {:stop, {:bad_event, state_name, event}, state_data}
  end

  @doc false
  def handle_sync_event(event, from, state_name, state_data) do
    {:stop, {:bad_sync_event, state_name, event}, state_data}
  end

  @doc false
  def handle_info(_msg, state_name, state_data) do
    {:next_state, state_name, state_data}
  end

  @doc false
  def terminate(_reason, _state_name, _state_data) do
    :ok
  end

  @doc false
  def code_change(_old, state_name, state_data, _extra) do
    {:ok, state_name, state_data}
  end

  # Helpers ------------------------------------------------------------------
end
