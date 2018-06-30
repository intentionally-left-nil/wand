defmodule Wand.Mode do
  @type t :: :caret | :tilde | :exact
  @no_patch ~r/^(\d+)\.(\d+)($|\+.*$|-.*$)/

  def from_requirement(requirement) do
    case Version.Parser.lexer(requirement, []) do
      [:==, _] -> :exact
      [:~>, _] -> :tilde
      [:>=, _, :&&, :<=, _]=p -> parse_caret_patch(p)
      [:>=, _, :&&, :<, _]=p -> parse_caret(p)
      _ -> :custom
    end
  end

  def get_requirement!(mode, version) do
    {:ok, requirement} = get_requirement(mode, version)
    requirement
  end

  def get_requirement(mode, :latest), do: {:ok, {:latest, mode}}

  def get_requirement(mode, version) when is_binary(version) do
    case parse(version) do
      {:ok, version} -> {:ok, get_requirement(mode, version)}
      :error -> {:error, :invalid_version}
    end
  end

  def get_requirement(:caret, %Version{major: 0, minor: 0} = version) do
    ">= #{version} and <= #{version}"
  end

  def get_requirement(:caret, %Version{major: 0, minor: minor} = version) do
    ">= #{version} and < 0.#{minor + 1}.0"
  end

  def get_requirement(:caret, %Version{major: major} = version) do
    ">= #{version} and < #{major + 1}.0.0"
  end

  def get_requirement(:exact, %Version{} = version) do
    "== #{version}"
  end

  def get_requirement(:tilde, %Version{} = version) do
    "~> #{version}"
  end

  defp add_missing_patch(version) do
    version
    |> String.replace(@no_patch, "\\1.\\2.0\\3")
  end

  defp parse(version) do
    add_missing_patch(version) |> Version.parse()
  end

  defp parse_caret_patch([:>=, old, :&&, :<=, new]) do
    case Version.compare(old, new) do
      :eq -> :caret
      _ -> :custom
    end
  end

  defp parse_caret([:>=, old, :&&, :<, new]) do
    old = Version.parse!(old)
    new = Version.parse!(new)
    cond do
      # patches are handled by parse_caret_patch
      # So anything that gets to here is not a caret.
      new.major == 0 and new.minor == 0 -> :custom
      new.patch != 0 -> :custom
      Version.compare(old, new) != :lt -> :custom

      # check for ^0.1.3
      new.major == 0 and old.major == 0 and old.minor + 1 == new.minor -> :caret

      # throw away all other cases of 0.x
      new.major == 0 or new.minor != 0 or old.major == 0 -> :custom

      # check for ^1.2.3
      new.major == old.major + 1 -> :caret
      true -> :custom
    end
  end
end
