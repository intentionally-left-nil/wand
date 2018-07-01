defmodule Wand.CLI.Commands.Add.Help do
  @moduledoc false
  def help(:banner) do
    """
    Add elixir packages to wand.json

    ## Usage
    **wand** add [package] [package] ... [flags]

    ## Examples
    ```
    wand add ex_doc mox --test
    wand add poison --git="https://github.com/devinus/poison.git"
    wand add poison@3.1 --exact
    ```

    ## Options
    The available flags depend on if wand is being used to add a single package, or multiple packages. Flags that can only be used in single-package-mode are denoted with (s).
    ```
    --compile           Run mix compile after adding (default: **true**)
    --compile-env   (s) The environment for the dependency (default: **prod**)
    --dev               Include the dependency in the dev environment
    --download          Run mix deps.get after adding (default: **true**)
    --env               Add the dependency to a specific environment
    --exact             Set the version to exactly match the version provided
    --git           (s) The Git URI to download the package from
    --hex           (s) The name of the package in hex to download
    --optional          Mark the dependency as optional
    --organization      Set the hex.pm organization to use
    --path          (s) The local directory to install the package from
    --prod              Include the dependency in the prod environment
    --read-app-file (s) Read the app file of the dependency (default: **true**)
    --repo              The hex repo to use (default: **hexpm**)
    --runtime           Start the application automatically (default: **true**)
    --sparse        (s) Checkout a given directory inside git
    --submodules    (s) Initialize submodules for the repo
    --test              Include the dependency in the test environment
    --tilde             Stay within the minor version provided
    --in-umbrella   (s) Sets a path dependency pointing to ../app
    ```
    """
    |> Wand.CLI.Display.print()
  end

  def help(:verbose) do
    Wand.CLI.Display.print(Wand.CLI.Commands.Add.moduledoc())
  end

  def help({:invalid_flag, flag}) do
    """
    #{flag} is invalid.
    Enter wand help add --verbose for more information
    """
    |> Wand.CLI.Display.print()
  end

  def help({:invalid_version, package}) do
    """
    #{package} contains an invalid version
    A version must conform to the SemVar schema.

    Some valid example versions are:
    <pre>
    3.1.0
    0.0.1
    2.0.0-dev
    </pre>

    Note that versions are not requirements and don't contain >=, ~> etc.
    """
    |> Wand.CLI.Display.print()
  end
end
