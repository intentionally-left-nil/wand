defmodule Wand.CLI.Commands.Add.Help do
  def help(:banner) do
    Wand.CLI.Display.print(Wand.CLI.Commands.Add.moduledoc())
  end

  def help(:verbose) do
    """
    Add elixir packages to wand.json

    ## Usage
    **wand** add [package] [package] ... [flags]
    Wand can be used to add packages from three different places: hex, git, or the local filesystem. [package] can either be the name, or name@version.

    If a version is provided, the --around and --exact flags determine how the version is used.

    ### Hex.pm
    Examples:
    <pre>
    wand add poison
    wand add poison@3.1
    </pre>

    ### Git
    Include the --git flag to pass a URI. The URI can be one of two base formats, and can end with an optional hash of the branch, tag, or ref to use
    Examples:
    <pre>
    wand add poison --git="https://github.com/devinus/poison.git"
    wand add poison --git="git@github.com:devinus/poison"
    wand add poison@3.1 --git="https://github.com/devinus/poison.git#test"
    wand add poison --git="https://github.com/devinus/poison.git#3.1.0"
    </pre>

    ### Local Path
    Local packages are described by passing in the --path flag corresponding to the path location

    OR, for an umbrella application, when you need to include a sibling dependency, pass the app name, along with the --in-umbrella flag.

    Examples:
    <pre>
    wand add poison --path="/absolute/path/to/poison"
    wand add poison --path="../../relative/path/"
    wand add sibling_dependency --in-umbrella
    </pre>

    ## Options
    The following flags are provided. They are boolean flags unless specified.

    ### Hex flags
    --hex=NAME means that the local name of the dependency is different from its name on hex
    E.g. wand add mypoison --hex=poison
    --organization=ORGANIZATION corresponds to the private org to pull the package(s) from.
    --repo=REPO An alternative repository to use. Configure with mix hex.repo. Default: hexpm

    ### Git flags
    --sparse=FOLDER git checkout only a single folder, and use that
    --submodules tells git to also initialize submodules

    ### Environment flags
    Setting these flags specifies which environments to install the dependency. If none are provided, all environments are included.

    **--env=ENVIRONMENT** where ENVIRONMENT is the environment to add. This flag can be added multiple times. Example: --env=prod --env=test

    --dev is shorthand for --env=dev
    --test is shorthand for --env=test
    --prod is shorthand for --env=prod

    --compile-env=ENVIRONMENT doesn't affect which environments the dependency is loaded from. Instead, it says "when compiling the dependency, which environment to use?". Defaults to --compile-env=prod

    --optional will include the project for THIS project, but not reuire it should the main project be a dependency of another project.

    ### Dependency configuration
    These flags deal with what happens with the dependency once configured
    --runtime determines whether to start the dependency's application. Defaults to true
    --read-app-file determines if the app file for the dependency is read. Defaults to true.
    --download determines if mix deps.get is run after adding the package to wand.json. Defaults to true. If set to false, this implies --compile=false as well.
    --compile determines if mix.compile is run after adding the package to wand.json.
    """
    |> Wand.CLI.Display.print()
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
