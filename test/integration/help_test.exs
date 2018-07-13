defmodule Wand.Integration.HelpTest do
  use Wand.Test.IntegrationCase, async: true

  ["", "help", "--verbose", "--?", "help --wrong-flag", "help add", "help core", "help help", "help init", "help outdated", "help remove", "help upgrade", "help version", "help wrong_command"]
  |> Enum.each(fn command ->
    test "wand #{command}" do
      assert wand(unquote(command)) == {:error, 1}
    end
  end)
end
