defmodule Wand.CLI.CoreValidator do
  alias Wand.CLI.Display
  import Wand.CLI.Errors, only: [error: 1]

  def require_core() do
    case Wand.CLI.Mix.core_version() do
      {:ok, version} -> validate_version(version)
      {:error, _} -> {:error, :require_core, :missing_core}
    end
  end

  defp validate_version(version) do
    version = String.trim(version)
    requirement = Wand.Mode.get_requirement!(:caret, Wand.version())

    case Version.match?(version, requirement) do
      true -> :ok
      false -> {:error, :require_core, {:version_mismatch, version}}
    end
  end

  def handle_error(:missing_core) do
    """
    # Error
    The wand_core archive task is missing, and needs to be installed. You can type wand core install to install the task
    """
    |> Display.error()

    error(:wand_core_missing)
  end

  def handle_error({:version_mismatch, version}) do
    """
    # Error
    The versions of wand and wand_core are out of sync.

    wand: #{Wand.version()}

    wand_core: #{version}

    Update one or both to get them back in sync. The easiest way is to:
    <pre>
    mix escript.install hex wand
    wand core install
    </pre>
    """
    |> Display.error()

    error(:bad_wand_core_version)
  end
end
