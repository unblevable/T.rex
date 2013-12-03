defmodule Trex.Request do

  @is_response_compact  "1"
  @num_wanted_peers     "50"
  @port                 "6881"

  def create(meta_info) do
    { :dict , raw_meta_info } = meta_info

    announce      = Dict.get(raw_meta_info, "announce")
    raw_info      = Dict.get(raw_meta_info, "info")
    |>  Trex.Bencode.encode

    params = [make_param({ "compact", @is_response_compact }),
      make_param({ "downloaded", Trex.Event.get_downloaded 1 }),
      make_param({ "event", Trex.Event.get 1 }),
      make_param({ "info_hash", :crypto.hash(:sha, raw_info) }),
      make_param({ "left", Trex.Event.get_left 1 }),
      # optional
      make_param({ "numwant", @num_wanted_peers }),
      # generate random digit (as string) for each placeholder (""); not
      # guaranteed to be unique (as of yet)
      make_param({ "peer_id", Trex.Client.id }),
      make_param({ "port", Trex.Client.port }),
      make_param({ "uploaded", Trex.Event.get_uploaded 1 })]
    |>  Enum.reject(fn(x) -> x == nil end)

    announce <> "/announce?" <> (params |> Enum.join "&")
  end

  def send(url) do
    case HTTPotion.get url do
      HTTPotion.Response[body: body, status_code: status_code] when status_code in 200..299 ->
        { :ok, { :dict, response } } = Trex.Bencode.decode body
        { :ok, response }
        # { :ok, Trex.Peer.start(response)}
      HTTPotion.Response[body: body] ->
        { :error, body }
    end
  end

  defp make_param({k, v}) do
    unless v == "" do
      k <> "=" <> (v |> URI.encode)
    end
  end

end
