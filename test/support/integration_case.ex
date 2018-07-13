defmodule Wand.Test.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :external
      alias Wand.Test.IntegrationRunner
      import  IntegrationRunner, only: [wand: 1, in_dir: 1, execute: 1, execute: 2]

      setup_all do
        :ok = IntegrationRunner.ensure_binary()
        :ok = IntegrationRunner.ensure_archive()
        :ok
      end

      setup do
        Mox.stub_with(WandCore.FileMock, Wand.Test.Integration.FileStub)
        :ok
      end
    end
  end
end

defmodule Wand.Test.Integration.FileStub do
  @behaviour WandCore.Interfaces.File
  @impl true
  def read(path), do: File.read(path)
  @impl true
  def write(path, contents), do: File.write(path, contents)
  @impl true
  def exists?(path), do: File.exists?(path)
end
