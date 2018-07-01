defmodule Wand do
  @moduledoc """
  A CLI tool for managing Elixir dependencies
  ## Usage
  **wand** [command] [flags]

  ## Available commands
  ```
  add         Add dependencies to your project
  core        Manage the related wand_core package
  help        Get detailed help
  init        Add the global wand tasks needed to use wand
  outdated    See the list of packages that are out of date
  remove      Remove dependencies from your project
  upgrade     Upgrade a dependency in your project
  version     Get the version of wand installed on the system
  ```

  Type **wand help --verbose** to see more detailed documentation, or
  Type **wand help [command]** to see information on a specific command

  ## Options
  ```
  --version   Get the version of wand installed on the system
  --verbose   Get detailed help
  --?         Same as --verbose
  ```
  """

  @doc false
  def banner(), do: @moduledoc

  @version Mix.Project.config() |> Keyword.get(:version, "unknown")
  def version(), do: @version
end
