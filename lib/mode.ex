defmodule Wand.Mode do

  @type t :: :caret | :tilde | :exact
  @no_patch ~r/^(\d+)\.(\d+)($|\+.*$|-.*$)/

  def get_requirement(mode, version) when is_binary(version) do
    case parse(version) do
      {:ok, version} -> get_requirement(mode, version)
      :error -> {:error, :invalid_version}
    end
  end

  def get_requirement(:caret, %Version{major: 0, minor: 0}=version) do
    "== #{version}"
  end

  def get_requirement(:caret, %Version{major: 0}=version) do
    "~> #{version}"
  end

  def get_requirement(:caret, %Version{major: major}=version) do
    ">= #{version} and < #{major + 1}.0.0"
  end

  def get_requirement(:exact, %Version{}=version) do
    "== #{version}"
  end

  def get_requirement(:tilde, %Version{}=version) do
    "~> #{version}"
  end

  defp add_missing_patch(version) do
    version
    |> String.replace(@no_patch, "\\1.\\2.0\\3")
  end

  defp parse(version) do
    add_missing_patch(version) |> Version.parse
  end
end
