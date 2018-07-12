defmodule Wand.CLI.Commands.Upgrade do
  use Wand.CLI.Command
  alias Wand.CLI.Display
  alias Wand.CLI.Commands.Upgrade

  @banner """
  # Upgrade
  Upgrade dependencies in your wand.json file

  ### Usage
  ```
  wand upgrade
  wand upgrade poison ex_doc --latest
  ```


  ## Options
  ```
  --compile           Run mix compile after adding (default: **true**)
  --download          Run mix deps.get after adding (default: **true**)
  --latest            Upgrade to the latest version, ignoring wand.json restrictions
  ```


  The following flags are additionally allowed if `--latest` is passed in:
  ```
  --exact             After updating, set the version in wand.json with ^ semantics
  --tilde             After updating, set the version in wand.json with ~> semantics
  ```
  """

  @moduledoc """
  #{@banner}



  By default, upgrade will respect the restrictions set in your wand.json file. Meaning,
  if your requirement is `>= 3.2.0 and < 4.0.0`, and the latest version in hex is `3.7.3`, wand will update the lower bound of wand.json to `3.7.3`, but leave the upper bound alone.



  If you want to update the upper bound, you need to use the --latest flag. The latest flag will always grab the newest (non pre) version in hex, and set that as the new lower bound. The upper bound is set to the next major version, unless you pass in the `--exact` or `--tilde` flags to override this behavior.



  Wand prefers setting versions by the caret semantic. That means that the lower bound is the exact version specified, and the upper bound is the next major version. If the version is less than 1.0.0, the upper bound becomes the next minor version, and so forth.

  """

  defmodule Options do
    @moduledoc false
    defstruct mode: :caret,
              download: true,
              compile: true,
              latest: false
  end

  @doc false
  @impl true
  def help(:banner), do: Display.print(@banner)
  @doc false
  @impl true
  def help(:verbose), do: Display.print(@moduledoc)

  @doc false
  @impl true
  def help({:invalid_flag, flag}) do
    """
    #{flag} is invalid.
    Allowed flags are --compile, --download, --exact, --latest, and --tilde.
    See wand help upgrade --verbose for more information
    """
    |> Display.print()
  end

  @impl true
  def options() do
    [
      require_core: true,
      load_wand_file: true,
    ]
  end

  @doc false
  @impl true
  def validate(args) do
    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: get_flags(args))

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> {:ok, parse(commands, switches)}
      error -> error
    end
  end

  @doc false
  @impl true
  def execute(args, extras), do: Upgrade.Execute.execute(args, extras)

  @doc false
  @impl true
  def handle_error(key, data), do: Upgrade.Execute.handle_error(key, data)

  defp parse(commands, switches) do
    download = Keyword.get(switches, :download, true)
    compile = download and Keyword.get(switches, :compile, true)

    options = %Options{
      download: download,
      compile: compile,
      latest: Keyword.get(switches, :latest, false),
      mode: get_mode(switches)
    }

    {get_packages(commands), options}
  end

  defp get_packages([]), do: :all
  defp get_packages(commands), do: commands

  defp get_mode(switches) do
    cond do
      Keyword.get(switches, :exact) -> :exact
      Keyword.get(switches, :tilde) -> :tilde
      true -> %Options{}.mode
    end
  end

  defp get_flags(args) do
    base_flags = [
      compile: :boolean,
      download: :boolean,
      latest: :boolean
    ]

    latest_flags = [
      exact: :boolean,
      tilde: :boolean
    ]

    {switches, _commands, _errors} = OptionParser.parse(args)

    case Keyword.get(switches, :latest) do
      true -> latest_flags ++ base_flags
      _ -> base_flags
    end
  end
end
