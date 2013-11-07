ExUnit.start

defmodule BencodeTest do

  use ExUnit.Case, async: true

  import Trex.Bencode

  @eof ""

  test "decodes integer" do
    assert decode("i12345e") == { :ok, 12345 }
  end

  test "decodes string" do
    assert decode("6:winter") == { :ok, "winter" }
  end

  test "decodes list" do
    assert decode("l5:fever6:wintere") ==
    { :ok, { :list, ["fever", "winter"] } }
  end

  test "decodes nested list" do
    assert decode("l5:feverl2:is3:wasee") ==
    { :ok, { :list, ["fever", { :list, ["is", "was"] }] } }
  end

  test "decodes dictionary" do
    hash_dict = HashDict.new
    |>  HashDict.put("maps", "atlases")
    |>  HashDict.put("arcade", "fire")

    assert decode("d4:maps7:atlases6:arcade4:firee", HashDict) ==
    { :ok, { :dict, hash_dict } }
  end

  test "decodes nested dictionary" do
    inner_hash_dict = HashDict.new
    |>  HashDict.put("perch", "is")
    |>  HashDict.put("beware", "fever")
    outer_hash_dict = HashDict.new
    |>  HashDict.put("maps", { :dict, inner_hash_dict })

    assert decode("d4:mapsd5:perch2:is6:beware5:feveree", HashDict) ==
    { :ok, { :dict, outer_hash_dict } }
  end

  test "decoder closes dictionary" do
    inner_hash_dict = HashDict.new
    |>  HashDict.put("perch", "is")
    outer_hash_dict = HashDict.new
    |>  HashDict.put("maps", { :dict, inner_hash_dict })
    |>  HashDict.put("fleet", "helplessness")

    assert decode("d4:mapsd5:perch2:ise5:fleet12:helplessnesse", HashDict) ==
    { :ok, { :dict, outer_hash_dict } }
  end

  test "encodes integer" do
    assert encode(12345) == "i12345e"
  end

  test "encodes string" do
    assert encode("maps") == "4:maps"
  end

  test "encodes list" do
    assert encode({ :list, ["fever", "winter"] }) == "l5:fever6:wintere"
  end

  test "encodes dictionary" do
    hash_dict = HashDict.new
    |>  HashDict.put("maps", "atlases")
    |>  HashDict.put("arcade", "fire")

    assert encode({ :dict, hash_dict }) == "d6:arcade4:fire4:maps7:atlasese"
  end

  test "encodes nested dictionary" do
    inner_hash_dict = HashDict.new
    |>  HashDict.put("perch", "is")
    |>  HashDict.put("beware", "fever")
    outer_hash_dict = HashDict.new
    |>  HashDict.put("maps", { :dict, inner_hash_dict })

    assert encode({ :dict, outer_hash_dict }) == "d4:mapsd6:beware5:fever5:perch2:isee"
  end

  test "encoded dictionary matches original binary" do
    { :ok, orig_bin } = File.read("resrc/flagfromserver.torrent")
    { :ok, dec_dict } = decode orig_bin
    enc_bin = encode(dec_dict) <> "\n"
    assert orig_bin == enc_bin
  end

end
