defmodule Wand do
  @moduledoc """
  Displays detailed help documentation for wand
  ## Usage
  **wand** [command] [flags]

  ## Available commands
  <pre>
  add         Add dependencies to your project
  help        Get detailed help
  init        Add the global wand tasks needed to use wand
  outdated    See the list of packages that are out of date
  remove      Remove dependencies from your project
  upgrade     Upgrade a dependency in your project
  version     Get the version of wand installed on the system
  </pre>

  You can type **wand help** [command] to see more information.

  ## Options
  <pre>
  --version   Get the version of wand installed on the system
  </pre>
  """

  @doc false
  def banner(), do: @moduledoc
end
