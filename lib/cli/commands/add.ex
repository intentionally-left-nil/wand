defmodule Wand.CLI.Commands.Add do
  @behaviour Wand.CLI.Command

  defmodule Package do
    defstruct name: nil,
              version: :latest,
              environments: [:all],
              runtime: true
  end

  def validate(args) do
    flags = [
      dev: :boolean,
      prod: :boolean,
      test: :boolean,
      env: :keep,
      runtime: :boolean,
    ]
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

  defp get_packages(packages, switches) do
    base_package = get_base_package(switches)
    packages =
      Enum.map(packages, fn package ->
        {name, version} = split_version(package)

        %Package{
          base_package |
          name: name,
          version: version,
        }
      end)

    {:ok, packages}
  end

  defp get_base_package(switches) do
    environments = get_environments(switches)
    runtime = Keyword.get(switches, :runtime, true)
    %Package {
      environments: environments,
      runtime: runtime,
    }
  end

  defp split_version(package) do
    case String.split(package, "@") do
      [package, version] -> {package, version}
      [package] -> {package, :latest}
    end
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
    environments ++ (Keyword.get_values(switches, :env)
    |> Enum.map(&String.to_atom/1))
  end

  defp get_environments(switches) do
    environments = add_predefined_environments([], switches)
    |> add_custom_environments(switches)

    case environments do
      [] -> [:all]
      environments -> environments
    end
  end
end
