use Mix.Config

if Mix.env() == :test do
  config :wand,
    file: Wand.FileMock,
    http: Wand.HttpMock,
    io: Wand.IOMock,
    system: Wand.SystemMock
end
