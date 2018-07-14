defmodule Wand.CLI.DependencyDownloader do
  def download() do
    case Wand.CLI.Mix.update_deps() do
      :ok -> :ok
      {:error, _reason} -> {:error, :install_deps_error, :download_failed}
    end
  end

  def handle_error(:install_deps_error, :download_failed) do
    """
    # Error
    Unable to run mix deps.get

    The wand.json file was successfully updated,
    however mix deps.get failed.
    """
  end
end
