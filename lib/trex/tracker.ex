defmodule Trex.Tracker do

  @moduledoc"""
  Send a request to a tracker and receive a response.
  """

  @is_response_compact  "1"
  @num_wanted_peers     "50"
  @port                 "6881"

  @doc"""
  Send a GET request to the tracker.
  """
  def request(metainfo) do
    create_request(metainfo)
    |> send_request
  end

  defp create_request(metainfo) do
    { :dict , raw_metainfo } = metainfo

    announce  = Dict.get(raw_metainfo, "announce")
    raw_info  = Dict.get(raw_metainfo, "info")
    info_hash = :crypto.hash(:sha, raw_info |> Trex.Bencode.encode)

    params = [{ "compact", @is_response_compact },
        { "downloaded", Trex.Event.get_downloaded info_hash },
        { "event",      Trex.Event.get info_hash },
        { "info_hash",  info_hash },
        { "left",       Trex.Event.get_left info_hash },
        { "numwant",    @num_wanted_peers },
        { "peer_id",    :crypto.rand_bytes(20) },
        { "port",       Trex.Client.port },
        { "uploaded",   Trex.Event.get_uploaded info_hash }]
    |>  Enum.reject(fn({ _k, v }) -> v == nil end)
    |>  Enum.map(fn({ k, v }) -> k <> "=" <> (v |> URI.encode) end)

    announce <> "?" <> (params |> Enum.join "&")
  end

  defp send_request(url) do
    URI.Info[scheme: _, query: query, fragment: _, authority: _, userinfo: _, host: host, port: port] = URI.parse url
    case :hackney.connect :hackney_tcp_transport, to_char_list(host), port, [] do
      { :ok, connection } ->
        case :hackney.send_request connection, { :get, "/announce?" <> query, [], '' } do
          { :ok, status_code, headers, res } when status_code in 200..299 ->
            case :hackney.body res do
              { :ok, body } ->
                Trex.Bencode.decode body
              { :error, _ } ->
                exit :bad_response
            end
          _ ->
            exit :bad_status_code
        { :error, _ } ->
          exit :bad_request
        end
      { :error, _ } ->
        exit :bad_connection
    end


    # { :ok, _, _, res } = :hackney.send_request connection, { :get, "/announce?" <> query, [], '' }
    # { :ok, body } = :hackney.body res

    # Trex.Bencode.decode body
  end

end
