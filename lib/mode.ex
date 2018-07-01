defmodule Wand.Mode do
  @type t :: :caret | :tilde | :exact | :custom
  @type requirement :: String.t() | {:latest, t}
  @type version :: String.t() | :latest | Version.t()
  @no_patch ~r/^(\d+)\.(\d+)($|\+.*$|-.*$)/

  @moduledoc """
  Each requirement in a wand.json follows some type of pattern. An exact pattern is one where the version is exactly specified. A tilde mode allows the patch version to be updated, and the caret mode allows the minor version to be updated.
  """

  @doc """
  Determine the mode that the requirement is currently using. If the requirement is not one of the types set by wand, it is marked as custom.

  ## Examples
      iex> Wand.Mode.from_requirement("== 2.3.2")
      :exact

      iex> Wand.Mode.from_requirement("~> 2.3.2")
      :tilde

      iex> Wand.Mode.from_requirement(">= 2.3.2 and < 3.0.0")
      :caret

      iex> Wand.Mode.from_requirement(">= 2.3.2 and < 3.0.0 and != 2.3.3")
      :custom
  """
  @spec from_requirement(requirement) :: t
  def from_requirement(:latest), do: :caret

  def from_requirement(requirement) do
    case Version.Parser.lexer(requirement, []) do
      [:==, _] -> :exact
      [:~>, _] -> :tilde
      [:>=, _, :&&, :<=, _] = p -> parse_caret_patch(p)
      [:>=, _, :&&, :<, _] = p -> parse_caret(p)
      _ -> :custom
    end
  end

  @doc """
  Given a mode and a version, calculate the requirement that combines both part. Throws an exception on failure.
  ## Examples
      iex> Wand.Mode.get_requirement!(:exact, "2.3.1")
      "== 2.3.1"

      iex> Wand.Mode.get_requirement!(:tilde, "2.3.1")
      "~> 2.3.1"

      iex> Wand.Mode.get_requirement!(:caret, "2.3.1")
      ">= 2.3.1 and < 3.0.0"

      iex> Wand.Mode.get_requirement!(:caret, "0.3.3")
      ">= 0.3.3 and < 0.4.0"
  """
  @spec get_requirement!(t, version) :: requirement
  def get_requirement!(mode, version) do
    {:ok, requirement} = get_requirement(mode, version)
    requirement
  end

  @doc """
  See `Wand.Mode.get_requirement!`
  On success, this returns {:ok, requirement}, and on failure, {:error, :invalid_version} is returned
  """
  @spec get_requirement(t, version) :: {:ok, requirement} | {:error, :invalid_version}
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
      new.major == 0 and new.minor == 0 ->
        :custom

      new.patch != 0 ->
        :custom

      Version.compare(old, new) != :lt ->
        :custom

      # check for ^0.1.3
      new.major == 0 and old.major == 0 and old.minor + 1 == new.minor ->
        :caret

      # throw away all other cases of 0.x
      new.major == 0 or new.minor != 0 or old.major == 0 ->
        :custom

      # check for ^1.2.3
      new.major == old.major + 1 ->
        :caret

      true ->
        :custom
    end
  end
end
