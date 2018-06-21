defmodule Wand.CLI.Commands.Add do
  @behaviour Wand.CLI.Command

  defmodule Args do
    defstruct package: nil
  end

  def validate(args) do
    {switches, ["add" | commands], _errors} = OptionParser.parse(args)
    get_packages(commands, switches)
  end

  defp get_packages([], switches), do: {:error, :missing_package}
  defp get_packages(packages, switches) do
    packages = Enum.map(packages, fn package -> %Args{
      package: package
    } end)
    {:ok, packages}
  end
end
