defmodule Wand.CLI.Commands.Add do
  @behaviour Wand.CLI.Command

  @moduledoc """
  Add elixir packages to wand.json for the project

  ## Usage
  **wand** add [package] [package] ... [flags]

  ## Examples
  **wand** add ex_doc mox --test
  **wand** add poison@https://github.com/devinus/poison.git
  **wand** add poison@3.1 --exact

  ## Options
  The available flags depend on if wand is being used to add a single package, or multiple packages. Flags that can only be used in single-package-mode are denoted with (s).

  --around            Stay within the minor version provided
  --branch        (s) Treat the url anchor as a git branch
  --compile           Run mix compile after adding (default: **true**)
  --compile-env   (s) The environment for the dependency (default: **prod**)
  --dev               Include the dependency in the dev environment
  --download          Run mix deps.get after adding (default: **true**)
  --env               Add the dependency to a specific environment
  --exact             Set the version to exactly match the version provided
  --hex-name      (s) The name of the package in hex to download
  --optional          Mark the dependency as optional
  --organization      Set the hex.pm organization to use
  --prod              Include the dependency in the prod environment
  --read-app-file (s) Read the app file of the dependency (default: **true**)
  --ref           (s) Treat the url anchor as a git ref
  --repo              The hex repo to use (default: **hexpm**)
  --runtime           Start the application automatically (default: **true**)
  --sparse        (s) Checkout a given directory inside git
  --submodules    (s) Initialize submodules for the repo
  --tag           (s) Treat the url anchor as a git tag
  --test              Include the dependency in the test environment
  --in-umbrella   (s) Sets a path dependency pointing to ../app
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
              repo: nil,
              version: :latest
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
              runtime: nil
  end

  def help(:banner), do: Wand.CLI.Display.print(@moduledoc)

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
        {name, version} = split_version(name)
        type = version_type(version)

        %Package{base_package | name: name}
        |> add_details(type, version, switches)
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

  defp split_version(package) do
    case String.split(package, "@", parts: 2) do
      [package, version] -> {package, version}
      [package] -> {package, :latest}
    end
  end

  defp add_details(package, :file, "file:" <> file, switches) do
    details = %Path{
      path: file,
      in_umbrella: Keyword.get(switches, :in_umbrella)
    }

    %Package{package | details: details}
  end

  defp add_details(package, :git, git_uri, switches) do
    details =
      case String.split(git_uri, "#", parts: 2) do
        [git_uri] ->
          %Git{uri: git_uri}

        [git_uri, ref] ->
          key =
            [:branch, :ref, :tag]
            |> Enum.find(:ref, &Keyword.get(switches, &1))

          data =
            %{uri: git_uri}
            |> Map.put(key, ref)

          struct(Git, data)
      end

    details = %Git{
      details
      | sparse: Keyword.get(switches, :sparse),
        submodules: Keyword.get(switches, :submodules)
    }

    %Package{package | details: details}
  end

  defp add_details(package, :hex, version, switches) do
    details = %Hex{
      version: version,
      organization: Keyword.get(switches, :organization),
      repo: Keyword.get(switches, :repo)
    }

    %Package{package | details: details}
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

  defp version_type("file:" <> _), do: :file
  defp version_type("https://" <> _), do: :git
  defp version_type("git@" <> _), do: :git
  defp version_type(_), do: :hex

  defp allowed_flags(args) do
    hex_flags = [
      hex_name: :string
    ]

    file_flags = [
      in_umbrella: :boolean
    ]

    git_flags = [
      branch: :boolean,
      ref: :boolean,
      tag: :boolean,
      sparse: :string,
      submodules: :boolean
    ]

    common_single_package_flags = [
      compile_env: :string,
      read_app_file: :boolean
    ]

    multi_package_flags = [
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
    ]

    {_switches, [_ | commands], _errors} = OptionParser.parse(args)

    if length(commands) == 1 do
      type =
        hd(commands)
        |> split_version
        |> elem(1)
        |> version_type

      flags =
        case type do
          :file -> file_flags
          :git -> git_flags
          :hex -> hex_flags
        end

      flags ++ common_single_package_flags ++ multi_package_flags
    else
      multi_package_flags
    end
  end
end
