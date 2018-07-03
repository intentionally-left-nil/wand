defmodule Wand.CLI.Executor do
  alias Wand.CLI.WandFileWithHelp
  alias Wand.CLI.CoreValidator
  alias WandCore.WandFile
  alias Wand.CLI.Error

  def run(module, data) do
    options = get_options(module)
    with :ok <- ensure_core(options),
    {:ok, file} <- ensure_wand_file_loaded(options),
    extras <- get_extras(file),
    {:ok, file_saved} <- execute(module, data, extras),
    :ok <- after_save(file_saved, module, data)
    do
      :ok
    else
      {:error, :require_core, reason} ->
        CoreValidator.handle_error(reason)

      {:error, :wand_file, reason} ->
        WandFileWithHelp.handle_error(reason)

      {:error, error_key, data} ->
        module.handle_error(error_key, data)
        Error.get(error_key)
    end
  end

  defp get_options(module) do
    if function_exported?(module, :options, 0) do
      module.options()
    else
      []
    end
  end

  defp get_extras(file) do
    [
      wand_file: file
    ]
    |> Enum.reject(&(&1 |> elem(1) == nil))
    |> Enum.into(%{})
  end

  defp execute(module, data, extras) do
    case module.execute(data, extras) do
      :ok -> {:ok, :file_not_saved}
      {:ok, %WandFile{}=file} -> save_file(module, file)
      error -> error
    end
  end

  defp save_file(module, file) do
    case WandFileWithHelp.save(file) do
      :ok -> {:ok, :file_saved}
      error -> error
    end
  end

  defp after_save(:file_not_saved, _, _), do: :ok
  defp after_save(:file_saved, module, data) do
    if function_exported?(module, :after_save, 1) do
      module.after_save(data)
    else
      :ok
    end
  end

  defp ensure_core(options) do
    case options[:require_core] do
      true -> CoreValidator.require_core()
      _ -> :ok
    end
  end

  defp ensure_wand_file_loaded(options) do
    case options[:load_wand_file] do
      true -> WandFileWithHelp.load()
      _ -> {:ok, nil}
    end
  end
end
