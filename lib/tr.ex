defmodule Tr do
  use Tr.Constants

  @moduledoc """
  A BitTorrent client.
  """

  @peer_id_length 20

  # Define defaults for optional keys.
  @metainfo %{
    "announce-list" => nil,
    "comment" => nil,
    "created by" => nil,
    "creation date" => nil,
    "encoding" => nil
  }

  @info %{
          # "md5sum" => nil,
          # "private" => nil
        }

  @doc false
  def read(path) do
    result =
      path
      |> Path.expand()
      |> File.open([:raw, :read_ahead], fn file ->
        case IO.binread(file, :all) do
          {:error, reason} ->
            # TODO: handle error
            IO.puts(:stderr, reason)
            exit(reason)

          data ->
            data
        end
      end)

    case result do
      {:error, reason} ->
        # TODO: handle error
        IO.puts(:stderr, reason)
        exit(reason)

      {:ok, data} ->
        data
    end
  end

  # TODO: temporary
  @doc false
  def process(filename) do
    metainfo =
      "data/#{filename}.torrent"
      |> Tr.read()
      |> Tr.Bencode.decode()

    # TODO: alphabetical order or order shown in spec?
    # TODO: "clients must reject invalid metainfo files"
    %{
      "announce" => announce,
      "announce-list" => _announce_list,
      "comment" => _comment,
      "created by" => _created_by,
      "creation date" => _creation_date,
      "encoding" => _encoding,
      "info" => info
    } = Map.merge(@metainfo, metainfo)

    info =
      %{
        "length" => length
        # "md5sum" => _md5_sum,
        # "name" => _name,
        # "piece length" => _piece_length,
        # "pieces" => _pieces,
        # "private" => _private
        # "path" => path,

        # multi-file data
        # "files" => files,
      } = Map.merge(@info, info)

    query_params = %{
      compact: 1,
      downloaded: 0,
      event: "started",
      # TODO: force pipe operator?
      info_hash: :crypto.hash(:sha, Tr.Bencode.encode(info)),
      # ip: "127.0.0.1",
      left: length,
      peer_id: generate_peer_id(),
      # TODO: Try port numbers sequentially if @port is taken
      port: @port,
      uploaded: 0
      # stopped: false,
    }

    response =
      "#{announce}?#{URI.encode_query(query_params)}"
      |> URI.parse
      |> Request.get()

    case response do
      {:ok, data} ->
        Tr.Bencode.decode(data)
    end
  end

  # Generate a peer id for the currently running client.
  #
  # Follow an "Azureus-style"-inspired convention for a unique peer id that is exactly 20 bytes
  # long.
  #
  # -RX0001-ccf23df2207
  #  ^ ^    ^
  #  1 2    3
  #
  #  1. T.rex's client id
  #
  #  2. version number
  #     TODO: how to convert 0.1.0 to something like 0001? use build number?
  #
  #  3. Hash
  #     This should fill the remaining bytes in the peer id. It is meant to be unique and random.
  #     The hash will be generated from a part of a SHA1 hash of the running process id (which
  #     should be unique enough).
  #
  defp generate_peer_id do
    prefix = "-#{@client_id}0001-"
    hash_length = @peer_id_length - byte_size(prefix)

    prefix <> :crypto.strong_rand_bytes(hash_length)
  end
end

defmodule Request do
  @moduledoc """
  Make a request (to a tracker).
  """

  @doc """
  @uri - %URI{} record
  """
  def get(uri) do
    %URI{
      host: host,
      path: path,
      port: port,
      query: query,
      scheme: scheme
    } = uri

    _ = :http
    _ = :https

    {:ok, conn} =
      scheme
      # TODO: handle error
      |> String.to_existing_atom()
      |> Mint.HTTP.connect(host, port)

    {:ok, conn, request_ref} = Mint.HTTP.request(conn, "GET", "#{path}?#{query}", [], nil)
    {:ok, conn, data} = receive_loop(conn, request_ref)

    Mint.HTTP.close(conn)

    {:ok, data}
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
                    [data] = data

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
