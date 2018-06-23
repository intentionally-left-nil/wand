defmodule Wand.CLI.Display.Renderer do
  alias Earmark.Block.{Heading,Para}
  alias IO.ANSI
  def render(blocks, context) do
    mapper = context.options.mapper
    text = mapper.(blocks, &(render_block(&1)))
    |> IO.iodata_to_binary()
    {context, text}
  end

  defp render_block(%Heading{content: content}) do
    [ANSI.underline(), content, ANSI.no_underline(), "\n"]
  end

  defp render_block(%Para{lines: lines}) do
    Enum.join(lines, "\n")
  end
end

defmodule Wand.CLI.Display do
  @io Wand.CLI.IO.impl()
  def print(message) do
    {blocks, context} = Earmark.parse(message)
    Wand.CLI.Display.Renderer.render(blocks, context)
    |> elem(1)
    |> @io.puts
  end
end
