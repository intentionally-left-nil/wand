defmodule CliTest do
  use ExUnit.Case, async: true
  import Mox
  setup :verify_on_exit!

  test "help returns a status code of 1" do
    stub_exit(1)
    Wand.CLI.main(["help"])
  end

  defp stub_exit(status) do
    expect(Wand.CLI.SystemMock, :halt, fn ^status -> :ok end)
  end
end
