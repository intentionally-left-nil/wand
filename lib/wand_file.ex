defmodule Wand.WandFile do
  @f Wand.File.impl()
  @requirement "~> 1.0"
  @vsn "1.0"

  defstruct version: @vsn,
  dependencies: []

  defmodule Dependency do
    @enforce_keys [:name]
    defstruct name: nil, requirement: nil, opts: %{}
  end

  def load(path \\ "wand.json") do
    with \
      {:ok, contents} <- @f.read(path),
      {:ok, data} <- Poison.decode(contents, keys: :atoms),
      {:ok, wand_file} <- validate(data)
    do
      {:ok, wand_file}
    else
      error -> error
    end
  end

  defp validate(data) do
    with \
      {:ok, version} <- validate_version(extract_version(data)),
      {:ok, dependencies} <- validate_dependencies(Map.get(data, :dependencies, %{}))
    do
      {:ok, %Wand.WandFile{version: to_string(version), dependencies: dependencies}}
    else
      error -> error
    end
  end

  defp validate_dependencies(dependencies) when not is_map(dependencies), do: {:error, :invalid_dependencies}

  defp validate_dependencies(dependencies) do
    {dependencies, errors} = Enum.map(dependencies, fn
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
    case Version.parse_requirement(requirement) do
      :error -> {:error, {:invalid_dependency, name}}
      _ -> %Dependency{name: name, requirement: requirement, opts: opts}
    end
  end
end
