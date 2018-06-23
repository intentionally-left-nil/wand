defmodule Wand.CLI.Display.Renderer do
  alias Earmark.Block.{Heading,Para}
  alias IO.ANSI
  def render(blocks, context) do
    mapper = context.options.mapper
    text = mapper.(blocks, &(render_block(&1, context)))
    |> IO.iodata_to_binary()
    {context, text}
  end

  def br(), do: "\n"
  def codespan(text), do: "`#{text}`"
  def em(text), do: ANSI.bright() <> text <> ANSI.normal()
  def strong(text), do: em(text)

  defp render_block(%Heading{content: content}, _context) do
    [ANSI.underline(), content, ANSI.no_underline(), "\n", "\n"]
  end

  defp render_block(%Para{lnb: lnb, lines: lines}, context) do
    %{value: value} = Earmark.Inline.convert(lines, lnb, context)
    unescape(value) <> "\n"
  end

  defp unescape(text) do
    # Reverse the action of
    # https://github.com/pragdave/earmark/blob/master/lib/earmark/helpers.ex#L56
    text
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
  end
end

defmodule Wand.CLI.Display do
  @io Wand.CLI.IO.impl()
  def print(message) do
    options = %Earmark.Options{renderer: Wand.CLI.Display.Renderer, smartypants: false}
    {blocks, context} = Earmark.parse(message, options)
    Wand.CLI.Display.Renderer.render(blocks, context)
    |> elem(1)
    |> String.trim_trailing("\n")
    |> @io.puts
  end
end
