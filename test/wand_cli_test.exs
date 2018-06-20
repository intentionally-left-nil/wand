defmodule WandCliTest do
  use ExUnit.Case
  doctest WandCli

  test "greets the world" do
    assert WandCli.hello() == :world
  end
end
