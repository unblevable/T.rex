defmodule Tr do
  @moduledoc """
  A BitTorrent client.
  """

  @doc false
  def start do
    Request.get("google.com")
  end
end

defmodule Request do
  @moduledoc """
  Make a request (to a tracker).
  """

  def get(domain) do
    # TODO: connect to open tracker
    {:ok, conn} = Mint.HTTP.connect(:http, domain, 80)
    {:ok, conn, request_ref} = Mint.HTTP.request(conn, "GET", "/", [], nil)
    {:ok, conn, data} = receive_loop(conn, request_ref)

    IO.inspect(data, label: :data, pretty: true)

    Mint.HTTP.close(conn)
  end

  defp receive_loop(conn, request_ref, data \\ []) do
    receive do
      message ->
        case Mint.HTTP.stream(conn, message) do
          :unknown ->
            # TODO: timeout?
            receive_loop(conn, request_ref, data)

          {:ok, conn, responses} ->
            {data, is_done} =
              Enum.reduce(responses, {data, false}, fn response, {data, _is_done} ->
                case response do
                  # TODO: return status_code
                  {:status, ^request_ref, _status_code} ->
                    # TODO: process non-200 status
                    {data, false}

                  # TODO: return headers
                  {:headers, ^request_ref, _headers} ->
                    {data, false}

                  {:done, ^request_ref} ->
                    # Note that this case is the final match and will resolve to `true` if matched
                    {data, true}

                  {:data, ^request_ref, binary} ->
                    {[binary | data], false}

                  # TODO: handle error?
                  {:error, ^request_ref, reason} ->
                    IO.inspect(reason, label: :error)
                    {data, true}
                end
              end)

            if is_done do
              {:ok, conn, data}
            else
              # Wait on the next message, since the stream of responses are incomplete
              receive_loop(conn, request_ref, data)
            end
        end
    end
  end
end
