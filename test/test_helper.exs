Mox.defmock(Wand.CLI.SystemMock, for: Wand.CLI.System)
Mox.defmock(Wand.CLI.DisplayMock, for: Wand.CLI.Display)

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
