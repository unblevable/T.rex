ExUnit.start

defmodule BencodeTest do

  use ExUnit.Case, async: true

  import Trex.Bencode

  @eof ""

  test "decodes integer" do
    assert parse_bin("i12345e") == { @eof, 12345 }
  end

  test "decodes string" do
    assert parse_bin("14:maps & atlases") == { @eof, "maps & atlases" }
  end

  test "decodes string and returns rest of file" do
    assert parse_bin("14:maps & atlases11:arcade fire") == { "11:arcade fire", "maps & atlases" }
  end

  test "decodes list" do
    assert parse_bin("l14:maps & atlases11:arcade firee") == { @eof, [ "maps & atlases", "arcade fire" ] }
  end

  test "decodes nested list" do
    assert parse_bin("l14:maps & atlasesl10:artichokes10:ted zanchaee") == { @eof, ["maps & atlases", ["artichokes", "ted zancha"]] }
  end

  test "decodes dictionary" do
    hash_dict = HashDict.new
    |>  HashDict.put("maps & atlases", "perch patchwork")
    |>  HashDict.put("arcade fire", "reflektor")

    assert parse_bin("d14:maps & atlases15:perch patchwork11:arcade fire9:reflektore") == { @eof, hash_dict }
  end

  test "decodes nested dictionary" do
    hash_dict = HashDict.new
    |>  HashDict.put("maps & atlases", HashDict.new
      |>  HashDict.put("perch patchwork", "artichokes")
      |>  HashDict.put("beware and be grateful", "winter"))

    assert parse_bin("d14:maps & atlasesd15:perch patchwork10:artichokes22:beware and be grateful6:winteree") == { @eof, hash_dict }
  end

  test "decoder closes dictionary" do
    hash_dict = HashDict.new
    |>  HashDict.put("arcade fire", HashDict.new
      |>  HashDict.put("reflektor", "reflektor"))
    |>  HashDict.put("fleet foxes", "helplessness blues")

    assert parse_bin("d11:arcade fired9:reflektor9:reflektore11:fleet foxes18:helplessness bluese") == { @eof, hash_dict }
  end

end
