defmodule Trex.Tracker do
  @moduledoc"""
  Make a request to a tracker and handle its responses.
  """

  alias Trex.Bencode

  # TODO: create + send request
  @doc """
  Creates and sends a GET request to the tracker and returns its response.
  """
  def request(request_url) do
    request_url
    |> send_request
    |> Bencode.decode
  end

  # TODO: better error handling
  defp send_request(uri) do
    case HTTPoison.get(uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        404
      {:error, %HTTPoison.Error{reason: reason}} ->
        reason
    end
  end
end
