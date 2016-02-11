defmodule Trex.Cli do
  @moduledoc """
  CLI parser
  """

  use GenServer

  alias Trex.Tracker
  alias Trex.Swarm

  def start_link(event_manager_name) do
    GenServer.start_link(__MODULE__, event_manager_name)
  end

  @doc """
  usage: trex <file> [options]

  options:

  -h, --help        output usage info
  """
  def run(argv) do
    argv
    |>  parse
    |>  process

  end

  defp parse(argv) do
    options =
      OptionParser.parse(argv, [
        switches: [help: :boolean],
        aliases: [h: :help]
      ])

    case options do
      {[help: true], _, _}        -> :help
      {_, [uri], _}               -> uri
      _                           -> :help
    end
  end

  defp process(:help) do
    IO.puts """
             .-=-==--==--.
       ..-=="  ,'o`)      `.
     ,'         `"'         \\
    :  (                     `.__...._
    |                  )    /         `-=-.
    :       ,vv.-._   /    /               `---==-._
     \\/\\/\\/VV ^ d88`;'    /                         `.
         ``  ^/d88P!'    /             ,              `._
            ^/    !'   ,.      ,      /                  "-,,__,,--';""'-.
           ^/    !'  ,'  \\ . .(      (         _           )  ) ) ) ))_,-.\\
          ^(__ ,!',"'   ;:+.:%:a.     \\:.. . ,'          )  )  ) ) ,"'    '
          ',,,'','     /o:::":%:%a.    \\:.:.:         .    )  ) _,'
           '""'       ;':::'' `+%%%a._  \\%:%|         ;.). _,-""
                  ,-='_.-'      ``:%::)  )%:|        /:._,"
                 (/(/"           ," ,'_,'%%%:       (_,'
                                (  (//(`.___;        \\
                                 \\     \\    `         `
                                  `.    `.   `.        :
    T.rex                           \\. . .\    : . . . :
    A BitTorrent client in Elixir    \\. . .:    `.. . .:
    -                                 `..:.:\\     \\:...\\
    (CJ)[http://ascii.co.uk/art/trex]  ;:.:.;      ::...:
                                       ):%::       :::::;
                                   __,::%:(        :::::
                                ,;:%%%%%%%:        ;:%::
                                  ;,--""-.`\\  ,=--':%:%:\\
                                 /"       "| /-".:%%%%%%%\\
                                                 ;,-"'`)%%)
                                                /"      "
    usage: trex [file|url|magnet] [options]

    options:

      default                 add torrent and start
      -c, --config            output config info
      -e, --exit              exit program
      -h, --help              output usage info
      -l, --list ["all"]      list ["active"] torrents
      -p, --processes [n]     spawn up to [1000] processes when applicable
      -r, --remove            remove torrent
      -t, --toggle            toggle torrent as active/inactive
      -v, --version           show version number
    """
  end

  # TODO: urls and magnets
  defp process(uri) do
    file =
      uri
      |> Path.relative_to_cwd
      |> File.read

    case file do
      {:error, error} ->
        :file.format(error)
        # System.halt(1)
      {:ok, binary} ->
        # TODO: refactor from a single flow of data transforms
        binary
        |> Tracker.request
        |> Swarm.connect
    end
  end
end
