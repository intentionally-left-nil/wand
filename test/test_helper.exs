Mox.defmock(Wand.CLI.SystemMock, for: Wand.CLI.System)

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
