defmodule Wand.WandEncoder do
  alias WandCore.WandFile
  alias WandCore.WandFile.Dependency
  alias WandCore.Poison.Encoder

  defimpl WandCore.Poison.Encoder, for: WandFile do
    @default_indent 2
    @default_offset 0

    def encode(%WandFile{version: version, dependencies: dependencies}, options) do
      indent = indent(options)
      offset = offset(options) + indent
      options = offset(options, offset)

      [
        {"version", version},
        {"dependencies", dependencies}
      ]
      |> Enum.map(fn {key, value} ->
        {encode(key, options), encode(value, options)}
      end)
      |> create_map_body(offset)
      |> wrap_map(offset, indent)
    end

    def encode([], _options), do: "{}"

    def encode(dependencies, options) when is_list(dependencies) do
      indent = indent(options)
      offset = offset(options) + indent
      options = offset(options, offset)

      dependencies =
        Enum.sort_by(dependencies, & &1.name)
        |> Enum.map(fn dependency ->
          {encode(dependency.name, options), encode(dependency, options)}
        end)

      create_map_body(dependencies, offset)
      |> wrap_map(offset, indent)
    end

    def encode(%Dependency{requirement: requirement, opts: opts}, options) when opts == %{} do
      Encoder.BitString.encode(requirement, options)
    end

    def encode(%Dependency{requirement: requirement, opts: opts}, options) do
      [requirement, opts]
      |> Encoder.List.encode(options)
    end

    def encode(key, options) when is_binary(key) do
      to_string(key)
      |> Encoder.BitString.encode(options)
    end

    defp wrap_map(body, offset, indent) do
      ["{\n", body, ?\n, spaces(offset - indent), ?}]
    end

    defp create_map_body(enumerable, offset) do
      Enum.reverse(enumerable)
      |> Enum.reduce([], fn {key, value}, acc ->
        [
          ",\n",
          spaces(offset),
          key,
          ": ",
          value
          | acc
        ]
      end)
      |> tl
    end

    defp indent(options) do
      Keyword.get(options, :indent, @default_indent)
    end

    defp offset(options) do
      Keyword.get(options, :offset, @default_offset)
    end

    defp offset(options, value) do
      Keyword.put(options, :offset, value)
    end

    defp spaces(count) do
      :binary.copy(" ", count)
    end
  end
end
