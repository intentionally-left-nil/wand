defmodule Wand.Test.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :external
      import  Wand.Test.IntegrationRunner, only: [wand: 1]

      setup_all do
         Wand.Test.IntegrationRunner.ensure_binary()
        :ok
      end
    end
  end
end
