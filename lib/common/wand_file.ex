defmodule WandCore.WandFile do
  alias WandCore.WandFile
  @f WandCore.Interfaces.File.impl()
  @requirement "~> 1.0"
  @vsn "1.0.0"

  defstruct version: @vsn,
            dependencies: []

  defmodule Dependency do
    @enforce_keys [:name]
    defstruct name: nil, requirement: nil, opts: %{}
  end

  def add(%WandFile{} = file, %Dependency{} = dependency) do
    case exists?(file, dependency.name) do
      false ->
        file = update_in(file.dependencies, &[dependency | &1])
        {:ok, file}

      true ->
        {:error, {:already_exists, dependency.name}}
    end
  end

  def load(path \\ "wand.json") do
    with {:ok, contents} <- read(path),
         {:ok, data} <- parse(contents),
         {:ok, wand_file} <- validate(data) do
      {:ok, wand_file}
    else
      error -> error
    end
  end

  def remove(%WandFile{} = file, name) do
    update_in(file.dependencies, fn dependencies ->
      Enum.reject(dependencies, &(&1.name == name))
    end)
  end

  def save(%WandFile{} = file, path \\ "wand.json") do
    contents = WandCore.Poison.encode!(file, pretty: true)
    @f.write(path, contents)
  end

  defp validate(data) do
    with {:ok, version} <- validate_version(extract_version(data)),
         {:ok, dependencies} <- validate_dependencies(Map.get(data, :dependencies, %{})) do
      {:ok, %WandCore.WandFile{version: to_string(version), dependencies: dependencies}}
    else
      error -> error
    end
  end

  defp validate_dependencies(dependencies) when not is_map(dependencies),
    do: {:error, :invalid_dependencies}

  defp validate_dependencies(dependencies) do
    {dependencies, errors} =
      Enum.map(dependencies, fn
        {name, [requirement, opts]} -> create_dependency(name, requirement, opts)
        {name, requirement} -> create_dependency(name, requirement, %{})
      end)
      |> Enum.split_with(fn
        %Dependency{} -> true
        _ -> false
      end)

    case errors do
      [] -> {:ok, dependencies}
      [error | _] -> error
    end
  end

  defp validate_version({:error, _} = error), do: error

  defp validate_version({:ok, version}) do
    if Version.match?(version, @requirement) do
      {:ok, version}
    else
      {:error, :version_mismatch}
    end
  end

  defp extract_version(%{version: version}) when is_binary(version) do
    case Version.parse(version) do
      :error -> {:error, :invalid_version}
      {:ok, version} -> {:ok, version}
    end
  end

  defp extract_version(%{version: _}), do: {:error, :invalid_version}
  defp extract_version(_data), do: {:error, :missing_version}

  defp create_dependency(name, requirement, opts) do
    name = to_string(name)

    case Version.parse_requirement(requirement) do
      :error -> {:error, {:invalid_dependency, name}}
      _ -> %Dependency{name: name, requirement: requirement, opts: opts}
    end
  end

  defp exists?(%WandFile{dependencies: dependencies}, name) do
    Enum.find(dependencies, &(&1.name == name)) != nil
  end

  defp parse(contents) do
    case WandCore.Poison.decode(contents, keys: :atoms) do
      {:ok, data} -> {:ok, data}
      {:error, _reason} -> {:error, :json_decode_error}
    end
  end

  defp read(path) do
    case @f.read(path) do
      {:ok, contents} -> {:ok, contents}
      {:error, reason} -> {:error, {:file_read_error, reason}}
    end
  end
end
