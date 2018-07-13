defmodule Wand.Integration.HelpTest do
  use Wand.Test.IntegrationCase, async: true

  test "wand" do
    assert "hello" == "world"
  end
end
