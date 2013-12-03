defmodule RequestTest do

  use ExUnit.Case, async: true

  test "creates request url" do
    info = ListDict.new
    |>  ListDict.put("pieces", "1")

    meta_info = ListDict.new
    |>  ListDict.put("announce", "http://tr.ex")
    |>  ListDict.put("info", { :dict, info })

    info_hash = :crypto.hash(:sha, Trex.Bencode.encode({ :dict, info })) |> URI.encode
    event = Trex.Event.get 1
    downloaded = Trex.Event.get_downloaded 1
    left = Trex.Event.get_left 1
    peer_id = Trex.Client.id |> URI.encode
    port = Trex.Client.port
    uploaded = Trex.Event.get_uploaded 1

    url = "http://tr.ex/announce?compact=1" <> "&downloaded=" <> downloaded <> "&event=" <> event <> "&info_hash=" <> info_hash <> "&left=" <> left <> "&numwant=50" <> "&peer_id=" <> peer_id <> "&port=" <> port <> "&uploaded=" <> uploaded

    assert url == Trex.Request.create({ :dict, meta_info })
  end

end
