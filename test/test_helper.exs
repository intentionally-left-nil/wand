ExUnit.configure(exclude: [external: true])
ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])

# wand_core is used both for getting dependencies, and within the main wand code during tests
# We want the behavior when getting the config to use the real wandcore, but mock it during the tests.
# This is accomplished by moving the mock out of config.ex and into the test_helper
Application.put_env(:wand_core, :file, WandCore.FileMock)
File.rm_rf!("./tmp")
Wand.Test.IntegrationRunner.init()
ExUnit.start()
