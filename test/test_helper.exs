ExUnit.configure(exclude: [external: true])
ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])

File.rm_rf!("./tmp")
Wand.Test.IntegrationRunner.init()
ExUnit.start()
