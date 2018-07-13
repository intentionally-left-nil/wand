defmodule Wand.Test.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :external
    end
  end
end
