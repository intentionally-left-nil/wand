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
      {:error, step, reason} -> handle_error(step, reason)
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
      {:error, reason} -> {:error, :wand_file_read, reason}
    end
  end

  defp handle_error(:wand_file_read, :json_decode_error) do
    error(:invalid_wand_file)
  end

  defp handle_error(:wand_file_read, reason) when reason in [:invalid_version, :missing_version, :version_mismatch] do
    error(:invalid_wand_file)
  end

  defp handle_error(:wand_file_read, {:file_read_error, _reason}) do
    error(:missing_wand_file)
  end

  defp handle_error(:wand_file_read, :invalid_dependencies) do
    error(:invalid_wand_file)
  end
end
