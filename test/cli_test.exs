defmodule CliTest do
  use ExUnit.Case, async: true
  alias Wand.CLI
  import Mox
  setup :verify_on_exit!

  test "help returns a status code of 1" do
    stub_exit(1)
    stub_display()
    CLI.main(["help"])
  end

  defp stub_exit(status) do
    expect(CLI.SystemMock, :halt, fn ^status -> :ok end)
  end

  defp stub_display() do
    expect(CLI.DisplayMock, :print, fn _message -> :ok end)
  end
end