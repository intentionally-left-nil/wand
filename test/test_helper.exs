ExUnit.configure(exclude: [external: true])
ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])

Wand.Test.IntegrationRunner.init()
ExUnit.start()
