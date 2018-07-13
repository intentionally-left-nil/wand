defmodule Wand.CLI.Command do
  @moduledoc """
  The interface for each type of command that wand supports.
  To add a new command, the following things must take place:

  1. Add the name of the module to routes below
  2. Create a module inside the lib/cli/commands folder that implements `Wand.CLI.Command`
  3. Update `Wand.CLI.ArgParser` if you need to add a shorthand version
  4. Update the help file in `Wand` with the appropriate text
  """

  @type ok_or_exit :: :ok | {:error, integer()}
  @callback after_save(data :: any()) :: ok_or_exit
  @callback execute(data :: any(), extras :: map()) :: ok_or_exit
  @callback handle_error(type :: atom, data :: any()) :: String.t()
  @callback help(type :: any()) :: any()
  @callback options() :: keyword()
  @callback validate(args :: list) :: {:ok, any()} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      alias Wand.CLI.Executor.Result
      @behaviour Wand.CLI.Command
      @impl true
      def after_save(_data), do: :ok

      @impl true
      def options(), do: []

      @impl true
      def handle_error(key, _data) do
        """
        Error: An unexpected error has occured
        The reason is: #{key}
        """
      end

      defoverridable Wand.CLI.Command
    end
  end

  def routes() do
    [
      "add",
      "core",
      "help",
      "init",
      "outdated",
      "remove",
      "upgrade",
      "version"
    ]
  end

  def get_module(name) when is_atom(name), do: get_module(to_string(name))

  def get_module(name) do
    Module.concat(Wand.CLI.Commands, String.capitalize(name))
  end

  def parse_errors([]), do: :ok

  def parse_errors([{flag, _} | _rest]) do
    {:error, {:invalid_flag, flag}}
  end
end
