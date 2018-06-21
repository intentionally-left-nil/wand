defmodule Wand.CLI.Commands.Add do
  @behaviour Wand.CLI.Command

  defmodule Package do
    defstruct environments: [:all],
              name: nil,
              optional: false,
              override: false,
              path: nil,
              runtime: true,
              version: :latest
  end

  def validate(args) do
    flags = [
      dev: :boolean,
      env: :keep,
      optional: :boolean,
      override: :boolean,
      path: :string,
      prod: :boolean,
      runtime: :boolean,
      test: :boolean,
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

  defp get_packages(names, switches) do
    base_package = get_base_package(switches)
    packages =
      Enum.map(names, fn name ->
          {name, version} = split_version(name)
          %Package{base_package | name: name}
          |> add_version(version)
      end)

    {:ok, packages}
  end

  defp get_switch(switches, key) do
    Keyword.get_lazy(switches, key, fn ->
      Map.fetch!(%Package{}, key)
    end)
  end

  defp get_base_package(switches) do
    %Package {
      environments: get_environments(switches),
      optional: get_switch(switches, :optional),
      override: get_switch(switches, :override),
      runtime: get_switch(switches, :runtime),
    }
  end

  defp split_version(package) do
    case String.split(package, "@") do
      [package, version] -> {package, version}
      [package] -> {package, :latest}
    end
  end

  defp add_version(package, "file:" <> path), do: %Package{package | path: path}
  defp add_version(package, version), do: %Package{package | version: version}

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
