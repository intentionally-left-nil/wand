use Mix.Config

if Mix.env() == :test do
  config :wand,
    http: Wand.HttpMock,
    io: Wand.IOMock,
    system: Wand.SystemMock
end
