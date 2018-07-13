defmodule Wand.Integration.HelpTest do
  use Wand.Test.IntegrationCase, async: true

  test "wand" do
    assert IntegrationRunner.ensure_binary() == 42
  end
end
