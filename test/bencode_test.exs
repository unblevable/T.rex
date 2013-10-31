ExUnit.start

defmodule BencodeTest do

  use ExUnit.Case, async: true

  import Trex.Bencode

  @eof ""

  test "decodes integer" do
    assert decode("i12345e") == 12345
  end

  test "decodes string" do
    assert decode("6:winter") == "winter"
  end

  test "decodes list" do
    assert decode("l5:fever6:wintere") == ["fever", "winter"]
  end

  test "decodes nested list" do
    assert decode("l5:feverl2:is3:wasee") == ["fever", ["is", "was"]]
  end

  test "decodes dictionary" do
    hash_dict = HashDict.new
    |>  HashDict.put("maps", "atlases")
    |>  HashDict.put("arcade", "fire")

    assert decode("d4:maps7:atlases6:arcade4:firee")
  end

  test "decodes nested dictionary" do
    hash_dict = HashDict.new
    |>  HashDict.put("maps", HashDict.new
      |>  HashDict.put("perch", "is")
      |>  HashDict.put("beware", "fever"))

    assert decode("d4:mapsd5:perch2:is6:beware5:feveree") == hash_dict
  end

  test "decoder closes dictionary" do
    hash_dict = HashDict.new
    |>  HashDict.put("maps", HashDict.new
      |>  HashDict.put("perch", "is"))
    |>  HashDict.put("fleet", "helplessness")

    assert decode("d4:mapsd5:perch2:ise5:fleet12:helplessnesse") == hash_dict
  end

  test "encodes integer" do
    assert encode(12345, @eof) == "i12345e"
  end

end
