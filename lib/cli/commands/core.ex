defmodule Wand.CLI.Commands.Core do
  use Wand.CLI.Command
  alias Wand.CLI.Display
  alias Wand.CLI.Error
  @io Wand.Interfaces.IO.impl()
  @moduledoc """
  # Core
  Manage the related wand_core package
  ### Usage
  ```
  wand core install
  wand core version
  ```



  Wand comes in two parts, the CLI and the wand.core tasks.
  In order to run mix deps.get, only the wand.core tasks are needed. For everything else, the CLI is needed.

  Wand validates to make sure the CLI is using a compatible version of wand_core. If they get out of sync, you can type wand core upgrade to fix the issue.
  """

  @doc false
  def help(:banner) do
    """
    Manage the related wand_core package
    ### Usage

    ```
    wand core install
    wand core version
    ```
    """
    |> Display.print()
  end

  @doc false
  def help(:verbose), do: Display.print(@moduledoc)

  @doc false
  def help(:wrong_command) do
    """
    The command is invalid.
    The correct commands are:
    <pre>
    wand core install
    wand core version
    </pre>
    See wand help core --verbose for more information
    """
    |> Display.print()
  end

  @doc false
  def validate(args) do
    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: get_flags(args))

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> parse(commands, switches)
      error -> error
    end
  end

  @doc false
  def execute(:version, _extras) do
    case Wand.CLI.Mix.core_version() do
      {:ok, version} ->
        String.trim(version)
        |> @io.puts()

        {:ok, %Result{message: nil}}

      {:error, _} ->
        missing_core()
    end
  end

  @doc false
  def execute(:install) do
    case Wand.CLI.Mix.install_core() do
      :ok -> :ok
      {:error, _} -> cannot_install()
    end
  end

  defp parse([], switches) do
    case Keyword.get(switches, :version) do
      true -> {:ok, :version}
      _ -> {:error, :wrong_command}
    end
  end

  defp parse(commands, _switches) do
    case commands do
      ["install"] -> {:ok, :install}
      ["version"] -> {:ok, :version}
      _ -> {:error, :wrong_command}
    end
  end

  defp get_flags(args) do
    {_switches, [_ | commands], _errors} = OptionParser.parse(args)

    case commands do
      ["version"] -> [version: :boolean]
      [] -> [version: :boolean]
      _ -> []
    end
  end

  defp cannot_install() do
    """
    # Error
    Could not install the wand_core archive. Please check the error message and then run wand core install again.
    """
    |> Display.error()

    {:error, 1}
  end

  defp missing_core() do
    """
    # Error
    Could not determine the version for wand_core.
    You can try installing it with wand core install
    """
    |> Display.error()

    Error.get(:wand_core_missing)
  end
end
