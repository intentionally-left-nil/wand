defmodule Wand.Integration.HelpTest do
  use Wand.Test.IntegrationCase, async: true

  test "wand" do
    assert wand("") == {:error, 1}
  end
end
