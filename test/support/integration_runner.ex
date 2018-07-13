defmodule Wand.Test.IntegrationRunner do
  use Modglobal

  def ensure_binary() do
    set_global(:test, 42)
    get_global(:test)
  end
end
