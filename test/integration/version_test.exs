defmodule Wand.Integration.VersionTest do
  use Wand.Test.IntegrationCase, async: true

  test "wand version" do
    assert wand("version") == :ok
  end
end
