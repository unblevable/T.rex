defmodule Trex.Cli do
  @moduledoc """
  CLI parser
  """

  use GenServer

  alias Trex.Spring

  @doc """
  usage: trex <file> [options]

  options:

  -h, --help        output usage info
  """
  def main(argv) do
    argv
    |>  parse
    |>  process
  end

  # Client -------------------------------------------------------------------

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  # Server -------------------------------------------------------------------

  # Helpers ------------------------------------------------------------------

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
    uri
    |> Path.relative_to_cwd
    |> File.read!
    |> Spring.start_torrent
  end
end
