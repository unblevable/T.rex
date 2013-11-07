defmodule Trex.Cli do

  @moduledoc"""
  CLI command parser
  """

  def run(argv) do
    argv
    |>  parse
    |>  process
  end

  defp parse(argv) do
    options = OptionParser.parse(argv,[
      switches: [help: :boolean, processes: :integer],
      aliases: [h: :help, p: :processes]])

    case options do
      { [help: true], _, _ }        -> :help
      { _, [uri], _ }               -> uri
      { [processes: n,], [uri], _ } -> { uri, n }
      _                             -> :help
    end
  end

  defp process(:help) do
    IO.puts"""
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
    -                            \\     \\    `         `
    T.rex                         `.    `.   `.        :
    a multi-threaded bittorrent     \\. . .\    : . . . :
    client written in Elixir.        \\. . .:    `.. . .:
    -                                 `..:.:\\     \\:...\\
    (CJ)[http://ascii.co.uk/art/trex]  ;:.:.;      ::...:
                                       ):%::       :::::;
                                   __,::%:(        :::::
                                ,;:%%%%%%%:        ;:%::
                                  ;,--""-.`\\  ,=--':%:%:\
                                 /"       "| /-".:%%%%%%%\\
                                                 ;,-"'`)%%)
                                                /"      "

    usage: trex [file|url|magnet] [options]

    options:

      default                 add torrent and start leeching
      -c, --config            output config info
      -e, --exit              exit program
      -h, --help              output usage info
      -l, --list [all]        list [active] torrents
      -p, --processes [n]     spawn up to [1000] processes when applicable
      -r, --remove            remove torrent
      -t, --toggle            toggle torrent as active/inactive
      -v, --version           show version number
    """
  end
  defp process(uri) when is_binary(uri) do
    uri
    |>  Path.relative_to_cwd
    |>  Trex.Request.make
  end
  defp process({ _uri, _n }) do
  end

end
