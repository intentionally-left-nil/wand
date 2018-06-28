defmodule DisplayTest do
  use ExUnit.Case, async: true
  import Mox
  alias Wand.CLI.Display
  alias IO.ANSI

  setup :verify_on_exit!

  @b ANSI.bright()
  @bb ANSI.normal()

  @u ANSI.underline()
  @uu ANSI.no_underline()

  @r ANSI.red()
  @rr ANSI.default_color()

  @t @u <> @b
  @tt @bb <> @uu

  test "print a simple string" do
    stub_io("Hello world")
    Display.print("Hello world")
  end

  test "multiple lines are different paragraphs" do
    stub_io("Hello\nworld")
    Display.print("Hello\nworld")
  end

  test "render multiple empty lines" do
    stub_io("Hello\n#{<<0x200B::utf8>>}\nworld")
    Display.print("Hello\n\nworld")
  end

  test "Adds underline to a title" do
    stub_io("#{@t}Hello#{@tt}")
    Display.print("# Hello")
  end

  test "combine text and an a title" do
    """
    #{@t}Lyrics#{@tt}

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
    |> Display.print()
  end

  test "bolded words" do
    stub_io("This is #{@b}bolded#{@bb} text")
    Display.print("This is **bolded** text")
  end

  test "underlined words" do
    stub_io("This is #{@u}underlined#{@uu} text")
    Display.print("This is _underlined_ text")
  end

  test "strip out pre tags" do
    """
    #{@t}Available commands#{@tt}

    add
    """
    |> String.trim_trailing("\n")
    |> stub_io

    """
    ## Available commands
    <pre>
    add
    </pre>
    """
    |> Display.print()
  end

  test "Handle HtmlOther for a single pre tag" do
    stub_io("hello")
    Display.print("<pre>hello</pre>")
  end

  test "trim trailing newlines" do
    stub_io("hello")
    Display.print("hello\n\n\n")
  end

  test "error message" do
    stub_stderr("hello")
    Display.error("hello")
  end

  defp stub_io(message) do
    message = "\n" <> message <> "\n"
    expect(Wand.IOMock, :puts, fn ^message -> :ok end)
  end

  defp stub_stderr(message) do
    message = @r <> "\n" <> message <> "\n" <> @rr
    expect(Wand.IOMock, :puts, fn(:stderr, ^message) -> :ok end)
  end
end
