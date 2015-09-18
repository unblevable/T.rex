defmodule BencodeTest do
  use ExUnit.Case, async: true

  doctest Trex.Bencode
  alias Trex.Bencode

  test "decodes integer" do
    assert Bencode.decode("i12345e") == 12345
  end

  test "decodes string" do
    assert Bencode.decode("6:winter") == "winter"
  end

  test "decodes list" do
    assert Bencode.decode("l5:fever6:wintere") == ["fever", "winter"]
  end

  test "decodes nested list" do
    assert Bencode.decode("l5:perchl2:is3:wasee") == ["perch", ["is", "was"]]
  end

  test "decodes dictionary with atoms as keys" do
    assert Bencode.decode("d6:arcade4:fire4:maps7:atlasese") ==
      %{arcade: "fire", maps: "atlases"}
  end

  test "decodes nested dictionary" do
    assert Bencode.decode("d4:mapsd6:beware5:fever5:perch2:isee") ==
      %{
        maps: %{
          beware: "fever",
          perch: "is"
        }
      }
  end

  test "encodes integer" do
    assert Bencode.encode(12345) == "i12345e"
  end

  test "encodes string" do
    assert Bencode.encode("maps") == "4:maps"
  end

  test "encodes list" do
    assert Bencode.encode(["fever", "winter"]) == "l5:fever6:wintere"
  end

  test "encodes dictionary with atoms as keys" do
    assert Bencode.encode(%{maps: "atlases"}) ==
      "d4:maps7:atlasese"
  end

  test "encodes dictionary with sorted keys" do
    assert Bencode.encode(%{"maps" => "atlases", "arcade" => "fire"}) ==
      "d6:arcade4:fire4:maps7:atlasese"
  end

  # test "encodes dictionary with sorted keys where keys are atoms and strings" do
  #   assert Bencode.encode(%{:maps => "atlases", "arcade" => "fire"}) ==
  #     "d6:arcade4:fire4:maps7:atlasese"
  # end

  test "encodes nested dictionary" do
    assert Bencode.encode(%{
      "maps" => %{
        "perch" => "is",
        "beware" => "fever"
      }
    }) == "d4:mapsd6:beware5:fever5:perch2:isee"
  end
end
