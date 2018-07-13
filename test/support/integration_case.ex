defmodule Wand.Test.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :external
      alias Wand.Test.IntegrationRunner

      setup_all do
        IntegrationRunner.ensure_binary()
        :ok
      end
    end
  end
end
