defmodule Wand.Test.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :external
      import  Wand.Test.IntegrationRunner, only: [wand: 1]

      setup_all do
        :ok = Wand.Test.IntegrationRunner.ensure_binary()
        :ok = Wand.Test.IntegrationRunner.ensure_archive()
        :ok
      end
    end
  end
end
