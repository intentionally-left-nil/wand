defmodule Wand.CLI.Commands.Add do
  @behaviour Wand.CLI.Command

  defmodule Args do
    defstruct package: nil,
              version: :latest,
              environments: [:all]
  end

  def validate(args) do
    flags = [
      dev: :boolean,
      prod: :boolean,
      test: :boolean,
    ]
    {switches, ["add" | commands], errors} = OptionParser.parse(args, strict: flags)

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
    environments = get_environments(switches)
    packages =
      Enum.map(packages, fn package ->
        {package, version} = split_version(package)

        %Args{
          package: package,
          version: version,
          environments: environments,
        }
      end)

    {:ok, packages}
  end

  defp split_version(package) do
    case String.split(package, "@") do
      [package, version] -> {package, version}
      [package] -> {package, :latest}
    end
  end

  defp get_environments(switches) do
    environments = [:dev, :test, :prod]
    |> Enum.reduce([], fn name, environments ->
      if Keyword.has_key?(switches, name) do
        [name | environments]
      else
        environments
      end
    end)

    case environments do
      [] -> [:all]
      environments -> environments
    end
  end
end
