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

  def help(:banner), do: Wand.CLI.Display.print(@moduledoc)

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
    --hex-name=NAME means that the local name of the dependency is different from its name on hex
    E.g. wand add mypoison --hex-name=poison
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

  def validate(args) do
    flags = allowed_flags(args)
    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case Wand.CLI.Command.parse_errors(errors) do
      :ok -> get_packages(commands, switches)
      error -> error
    end
  end

  defp get_packages([], _switches), do: {:error, :missing_package}

  defp get_packages(names, switches) do
    base_package = get_base_package(switches)

    packages =
      Enum.map(names, fn name ->
        {name, requirement} = split_name(name)
        type = package_type(switches)

        %Package{base_package | name: name, requirement: requirement}
        |> add_details(type, switches)
      end)

    {:ok, packages}
  end

  defp get_base_package(switches) do
    download = Keyword.get(switches, :download, true)
    compile = download and Keyword.get(switches, :compile, true)

    %Package{
      compile: compile,
      compile_env: Keyword.get(switches, :compile_env),
      download: download,
      environments: get_environments(switches),
      mode: get_mode(switches),
      optional: Keyword.get(switches, :optional),
      override: Keyword.get(switches, :override),
      read_app_file: Keyword.get(switches, :read_app_file),
      runtime: Keyword.get(switches, :runtime)
    }
  end

  defp split_name(package) do
    case String.split(package, "@", parts: 2) do
      [package, name] -> {package, name}
      [package] -> {package, :latest}
    end
  end

  defp add_details(package, :path, switches) do
    details = %Path{
      path: Keyword.fetch!(switches, :path),
      in_umbrella: Keyword.get(switches, :in_umbrella)
    }

    %Package{package | details: details}
  end

  defp add_details(package, :git, switches) do
    {uri, ref} = case String.split(Keyword.fetch!(switches, :git), "#", parts: 2) do
      [uri] -> {uri, nil}
      [uri, ref] -> {uri, ref}
    end
    details = %Git{
      uri: uri,
      sparse: Keyword.get(switches, :sparse),
      submodules: Keyword.get(switches, :submodules),
      ref: ref
    }
    %Package{package | details: details}
  end

  defp add_details(package, :hex, switches) do
    details = %Hex{
      organization: Keyword.get(switches, :organization),
      repo: Keyword.get(switches, :repo)
    }

    %Package{package | details: details}
  end

  defp add_details(package, :umbrella, switches) do
    %Package{package | details: %Path{in_umbrella: true}}
  end

  defp add_predefined_environments(environments, switches) do
    [:dev, :test, :prod]
    |> Enum.reduce(environments, fn name, environments ->
      if Keyword.has_key?(switches, name) do
        [name | environments]
      else
        environments
      end
    end)
  end

  defp add_custom_environments(environments, switches) do
    environments ++
      (Keyword.get_values(switches, :env)
       |> Enum.map(&String.to_atom/1))
  end

  defp get_environments(switches) do
    environments =
      add_predefined_environments([], switches)
      |> add_custom_environments(switches)

    case environments do
      [] -> [:all]
      environments -> environments
    end
  end

  defp get_mode(switches) do
    exact = Keyword.get(switches, :exact)
    around = Keyword.get(switches, :around)

    cond do
      exact -> :exact
      around -> :around
      true -> :normal
    end
  end

  defp package_type(switches) do
    cond do
      Keyword.has_key?(switches, :git) -> :git
      Keyword.has_key?(switches, :path) -> :path
      Keyword.has_key?(switches, :in_umbrella) -> :umbrella
      true -> :hex
    end
  end

  defp allowed_flags(args) do
    all_flags = %{
      hex: [
        hex_name: :string
      ],
      path: [
        path: :string,
        in_umbrella: :boolean,
      ],
      git: [
        git: :string,
        sparse: :string,
        submodules: :boolean
      ],
      umbrella: [
        in_umbrella: :boolean,
      ],
      single_package: [
        compile_env: :string,
        read_app_file: :boolean,
      ],
      multi_package: [
        around: :boolean,
        compile: :boolean,
        dev: :boolean,
        download: :boolean,
        env: :keep,
        exact: :boolean,
        optional: :boolean,
        organization: :string,
        override: :boolean,
        prod: :boolean,
        repo: :string,
        runtime: :boolean,
        test: :boolean
      ],
    }

    {switches, [_ | commands], _errors} = OptionParser.parse(args)

    case length(commands) do
      1 -> [:single_package, :multi_package, package_type(switches)]
      _ -> [:multi_package]
    end
    |> Enum.flat_map(&Map.fetch!(all_flags, &1))
  end
end
