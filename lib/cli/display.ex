defmodule Wand.CLI.Display do
  @callback print(message :: String.t()) :: :ok

  def impl() do
    Application.get_env(:wand, :display, Wand.CLI.Display.Impl)
  end
end

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

defmodule Wand.CLI.Display.Impl do
  @behaviour Wand.CLI.Display

  def print(message) do
    {blocks, context} = Earmark.parse(message)
    Wand.CLI.Display.Renderer.render(blocks, context)
    |> elem(1)
    |> IO.puts

    :ok
  end
end
