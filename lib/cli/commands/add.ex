defmodule Wand.CLI.Commands.Add do
  @behaviour Wand.CLI.Command

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
    defstruct compile_env: nil,
              details: %Hex{},
              environments: [:all],
              name: nil,
              optional: nil,
              override: nil,
              read_app_file: nil,
              runtime: nil
  end

  def validate(args) do
    flags = allowed_flags(args)
    {switches, [_ | commands], errors} = OptionParser.parse(args, strict: flags)

    case parse_errors(errors) do
      :ok -> get_packages(commands, switches)
      error -> error
    end
  end

  defp parse_errors([]), do: :ok

  defp parse_errors([{flag, _} | _rest]) do
    {:error, {:invalid_flag, flag}}
  end

  defp get_packages([], _switches), do: {:error, :missing_package}

  defp get_packages(names, switches) do
    base_package = get_base_package(switches)

    packages =
      Enum.map(names, fn name ->
        {name, version} = split_version(name)

        %Package{base_package | name: name}
        |> add_details(version, switches)
      end)

    {:ok, packages}
  end

  defp get_base_package(switches) do
    %Package{
      environments: get_environments(switches),
      optional: Keyword.get(switches, :optional),
      override: Keyword.get(switches, :override),
      runtime: Keyword.get(switches, :runtime)
    }
  end

  defp split_version(package) do
    case String.split(package, "@") do
      [package, version] -> {package, version}
      [package] -> {package, :latest}
    end
  end

  defp add_details(package, "file:" <> file, switches) do
    details = %Path{
      path: file,
      in_umbrella: Keyword.get(switches, :in_umbrella)
    }

    %Package{package | details: details}
  end

  defp add_details(package, version, _switches) do
    details = %Hex{
      version: version
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

  defp allowed_flags(args) do
    single_package_flags = [
      compile_env: :boolean,
      hex_name: :string,
      read_app_file: :boolean,
      sparse: :string,
      submodules: :boolean,
    ]

    multi_package_flags = [
      dev: :boolean,
      env: :keep,
      optional: :boolean,
      organization: :string,
      override: :boolean,
      prod: :boolean,
      repo: :string,
      runtime: :boolean,
      test: :boolean,
    ]

    {_switches, [_ | commands], _errors} = OptionParser.parse(args)
    case commands do
      [_item] -> single_package_flags ++ multi_package_flags
      _ -> multi_package_flags
    end
  end
end
