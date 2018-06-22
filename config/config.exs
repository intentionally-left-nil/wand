use Mix.Config

impls = case Mix.env() do
  :test -> [
    system: Wand.CLI.SystemMock
  ]
  _ -> [
    system: System
  ]
end

config :wand, impls
