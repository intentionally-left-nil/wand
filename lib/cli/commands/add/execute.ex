defmodule Wand.CLI.Commands.Add.Execute do
  alias Wand.CLI.Commands.Add.Package
  alias Wand.WandFile
  alias Wand.WandFile.Dependency
  def execute(packages) do
    {:ok, file} = WandFile.load()
    packages
    |> Enum.map(&Task.async(fn -> get_dependency(&1) end))
    |> Enum.map(&Task.await/1)
    |> Enum.reduce(file, fn (dependency, file) ->
       WandFile.add(file, dependency) |> elem(1)
     end)
    |> WandFile.save()
  end

  defp get_dependency(%Package{name: name, requirement: :latest}=package) do
    {:ok, [version | _]} = Wand.Hex.releases(name)
    requirement = get_requirement(version, package.mode)
    %Dependency{name: name, requirement: requirement}
  end

  defp get_requirement(version, :normal) do
    "~> " <> version
  end
end
