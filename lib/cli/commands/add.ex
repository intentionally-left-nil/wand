defmodule Wand.CLI.Commands.Add do
  @behaviour Wand.CLI.Command

  @moduledoc """
  Add elixir packages to wand.json

  ## Usage
  **wand** add [package] [package] ... [flags]

  ## Examples
  <pre>
  **wand** add ex_doc mox --test
  **wand** add poison --git=https://github.com/devinus/poison.git
  **wand** add poison@3.1 --exact
  </pre>

  ## Options
  The available flags depend on if wand is being used to add a single package, or multiple packages. Flags that can only be used in single-package-mode are denoted with (s).
  <pre>
  --around            Stay within the minor version provided
  --compile           Run mix compile after adding (default: **true**)
  --compile-env   (s) The environment for the dependency (default: **prod**)
  --dev               Include the dependency in the dev environment
  --download          Run mix deps.get after adding (default: **true**)
  --env               Add the dependency to a specific environment
  --exact             Set the version to exactly match the version provided
  --git           (s) The Git URI to download the package from
  --hex-name      (s) The name of the package in hex to download
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
  --in-umbrella   (s) Sets a path dependency pointing to ../app
  </pre>
  """

  defmodule Git do
    defstruct uri: nil,
              ref: nil,
              branch: nil,
              tag: nil,
              sparse: nil,
              submodules: nil
  end

  defmodule Hex do
    defstruct hex_name: nil,
              organization: nil,
              repo: nil
  end

  defmodule Path do
    defstruct path: nil,
              in_umbrella: nil
  end

  defmodule Package do
    defstruct compile: true,
              compile_env: nil,
              details: %Hex{},
              download: true,
              environments: [:all],
              mode: :normal,
              name: nil,
              optional: nil,
              override: nil,
              read_app_file: nil,
              requirement: :latest,
              runtime: nil
  end

  def moduledoc(), do: @moduledoc
  def help(type), do: Wand.CLI.Commands.Add.Help.help(type)

  def validate(args), do: Wand.CLI.Commands.Add.Validate.validate(args)

  def execute(%Package{}=package), do: Wand.CLI.Commands.Add.Execute.execute(package)
end
