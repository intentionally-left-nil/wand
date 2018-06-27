defmodule Wand.CLI.Commands.Add.Execute do
  alias Wand.CLI.Commands.Add.{Git, Hex, Package, Path}
  def execute(packages) do
    packages
    |> Enum.map(&Task.async(fn -> add_package(&1) end))
    |> Enum.map(&Task.await/1)
  end

  defp add_package(%Package{requirement: :latest}=package) do
    {:ok, [latest | _]} = Wand.Hex.releases(package.name)

  end
end
