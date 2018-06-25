defmodule Wand.WandFile do
  @f Wand.File.impl()

  def load(path \\ "wand.json") do
    @f.read(path)
    |> parse
  end

  defp parse({:ok, contents}), do: Poison.decode(contents)
  defp parse({:error, _} = error), do: error
end
