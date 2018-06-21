defmodule Wand.CLI.Commands.Add do
  @behaviour Wand.CLI.Command

  defmodule Args do
    defstruct package: nil,
              version: :latest
  end

  def validate(args) do
    {switches, ["add" | commands], _errors} = OptionParser.parse(args)
    get_packages(commands, switches)
  end

  defp get_packages([], switches), do: {:error, :missing_package}

  defp get_packages(packages, switches) do
    packages =
      Enum.map(packages, fn package ->
        {package, version} = split_version(package)

        %Args{
          package: package,
          version: version
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
end
