defmodule DisplayTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Wand.CLI.Display.Impl, as: Display
  alias IO.ANSI

  test "print a simple string" do
    assert print("Hello world") == "Hello world\n"
  end

  test "Adds underline to a title" do
    assert print("# Hello") == "#{ANSI.underline()}Hello#{ANSI.no_underline()}\n"
  end

  defp print(message) do
    capture_io(fn -> Display.print(message) end)
  end
end
