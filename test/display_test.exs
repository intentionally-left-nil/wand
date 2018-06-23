defmodule DisplayTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Display
  alias IO.ANSI

  setup :verify_on_exit!

  test "print a simple string" do
    stub_io("Hello world")
    Display.print("Hello world")
  end

  test "Adds underline to a title" do
    stub_io("#{ANSI.underline()}Hello#{ANSI.no_underline()}\n")
    Display.print("# Hello")
  end

  test "combine text and an a title" do
    """
    #{ANSI.underline()}Lyrics#{ANSI.no_underline()}
    This is America
    Don't catch you slippin' up
    """
    |> String.trim_trailing("\n")
    |> stub_io

    """
    # Lyrics
    This is America
    Don't catch you slippin' up
    """
    |> Display.print
  end

  defp stub_io(message) do
    expect(Wand.CLI.IOMock, :puts, fn ^message -> :ok end)
  end
end
