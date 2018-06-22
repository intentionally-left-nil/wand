use Mix.Config

if Mix.env() == :test do
  config :wand,
  system: Wand.CLI.SystemMock,
  display: Wand.CLI.DisplayMock
end
