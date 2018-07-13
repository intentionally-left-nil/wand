defmodule Wand.Test.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :external
      alias Wand.Test.IntegrationRunner
    end
  end
end
