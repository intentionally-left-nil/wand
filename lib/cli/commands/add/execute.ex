defmodule Wand.CLI.Commands.Add.Execute do
  alias Wand.CLI.Commands.Add.Package
  alias Wand.WandFile
  alias Wand.WandFile.Dependency
  import Wand.CLI.Errors, only: [error: 1]

  def execute(packages) do
    with \
      {:ok, file} <- load_file()
    do
      packages
      |> Enum.map(&Task.async(fn -> get_dependency(&1) end))
      |> Enum.map(&Task.await/1)
      |> Enum.reduce(file, fn (dependency, file) ->
         WandFile.add(file, dependency) |> elem(1)
       end)
      |> WandFile.save()
    else
      error -> error
    end
  end

  defp get_dependency(%Package{name: name, requirement: :latest}=package) do
    {:ok, [version | _]} = Wand.Hex.releases(name)
    requirement = get_requirement(version, package.mode)
    %Dependency{name: name, requirement: requirement}
  end

  defp get_requirement(version, :normal) do
    "~> " <> version
  end

  defp load_file() do
    case WandFile.load() do
      {:ok, file} -> {:ok, file}
      {:error, _reason} -> error(:missing_wand_file)
    end
  end
end
