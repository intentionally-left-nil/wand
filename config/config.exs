use Mix.Config

if Mix.env() == :test do
  config :wand,
    file: Wand.FileMock,
    hex_api: Wand.Hex.ApiMock,
    io: Wand.CLI.IOMock,
    system: Wand.CLI.SystemMock
end
