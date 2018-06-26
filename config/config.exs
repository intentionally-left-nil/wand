use Mix.Config

if Mix.env() == :test do
  config :wand,
    file: Wand.FileMock,
    io: Wand.CLI.IOMock,
    system: Wand.CLI.SystemMock
end
