defmodule Wand.CLI.Commands.Add do
  use Wand.CLI.Command

  @moduledoc """
  # Add
  Add elixir packages to wand.json

  ### Usage
  **wand** add [package] [package] ... [flags]

  Wand can be used to add packages from three different places: hex, git, or the local filesystem. [package] can either be the name, or name@version.

  If a version is provided, the `--around` and `--exact` flags determine how the version is used.

  ### Hex.pm
  Examples:
  ```
  wand add poison
  wand add poison@3.1
  ```



  ### Git
  Include the `--git` flag to pass a URI. The URI can be one of two base formats, and can end with an optional hash of the branch, tag, or ref to use
  Examples:
  ```
  wand add poison --git="https://github.com/devinus/poison.git"
  wand add poison --git="git@github.com:devinus/poison"
  wand add poison@3.1 --git="https://github.com/devinus/poison.git#test"
  wand add poison --git="https://github.com/devinus/poison.git#3.1.0"
  ```



  ### Local Path
  Local packages are described by passing in the `--path` flag corresponding to the path location

  OR, for an umbrella application, when you need to include a sibling dependency, pass the app name, along with the `--in-umbrella` flag.

  Examples:
  ```
  wand add poison --path="/absolute/path/to/poison"
  wand add poison --path="../../relative/path/"
  wand add sibling_dependency --in-umbrella
  ```

  ## Options
  The following flags are provided. They are boolean flags unless specified.



  ### Hex flags
  ```
  --hex=NAME means that the local name of the dependency is different from its name on hex
  E.g. wand add mypoison --hex=poison
  --organization=ORGANIZATION corresponds to the private org to pull the package(s) from.
  --repo=REPO An alternative repository to use. Configure with mix hex.repo. Default: hexpm
  ```



  ### Git flags
  ```
  --sparse=FOLDER git checkout only a single folder, and use that
  --submodules tells git to also initialize submodules
  ```



  ### Environment flags
  Setting these flags specifies which environments to install the dependency. If none are provided, all environments are included.

  ```
  --env=ENVIRONMENT where ENVIRONMENT is the environment to add. This flag can be added multiple times. Example: --env=prod --env=test

  --dev is shorthand for --env=dev
  --test is shorthand for --env=test
  --prod is shorthand for --env=prod

  --compile-env=ENVIRONMENT doesnt affect which environments the dependency is loaded from. Instead, it says "when compiling the dependency, which environment to use?". Defaults to --compile-env=prod

  --optional will include the project for THIS project, but not reuire it should the main project be a dependency of another project.
  ```



  ### Dependency configuration
  These flags deal with what happens with the dependency once configured
  ```
  --runtime determines whether to start the dependency. Defaults to true
  --read-app-file determines if the app file for the dependency is read. Defaults to true.
  --download determines if mix deps.get is run after adding the package to wand.json. Defaults to true.
  ```
  """

  defmodule Git do
    @moduledoc false
    defstruct git: nil,
              ref: nil,
              sparse: nil,
              submodules: false
  end

  defmodule Hex do
    @moduledoc false
    defstruct hex: nil,
              organization: nil,
              repo: :hexpm
  end

  defmodule Path do
    @moduledoc false
    defstruct path: nil,
              in_umbrella: false
  end

  defmodule Package do
    @moduledoc false
    @default_requirement Wand.Mode.get_requirement!(:caret, :latest)
    defstruct compile_env: :prod,
              details: %Hex{},
              download: true,
              only: nil,
              name: nil,
              optional: false,
              override: false,
              read_app_file: true,
              requirement: @default_requirement,
              runtime: true
  end

  @doc false
  def moduledoc(), do: @moduledoc

  @doc false
  @impl true
  def help(type), do: Wand.CLI.Commands.Add.Help.help(type)

  @doc false
  @impl true
  def options() do
    [
      require_core: true,
      load_wand_file: true
    ]
  end

  @doc false
  @impl true
  def validate(args), do: Wand.CLI.Commands.Add.Validate.validate(args)

  @doc false
  @impl true
  def execute(packages, extras), do: Wand.CLI.Commands.Add.Execute.execute(packages, extras)

  @doc false
  @impl true
  def after_save(packages), do: Wand.CLI.Commands.Add.Execute.after_save(packages)

  @doc false
  @impl true
  def handle_error(key, data), do: Wand.CLI.Commands.Add.Error.handle_error(key, data)
end
