# Wand [![Hex version badge](https://img.shields.io/hexpm/v/wand.svg)](https://hex.pm/packages/wand)

**wand** is a dependency manager that uses a _wand.json_ file to replace your deps() in mix.exs. This allows you to add, remove, and upgrade packages easily using the wand cli.

## Quickstart
To install, paste into a terminal: `mix archive.install hex wand_core --force && mix escript.install hex wand --force`

To use wand in a project: `wand init`

Add a dependency: `wand add poison`

Remove a dependency: `wand remove poison`

Upgrade a dependency: `wand upgrade poison --latest`

help: `wand --?`

## How it works
Wand works by removing your dependencies from mix.exs and storing them instead in `wand.json`. This is necessary because `mix.exs` is a _code_ file - it's regular elixir. This makes programatically updating dependencies hard because of the complex mix.exs files folks can have. Instead, by saving the dependencies in `wand.json`, wand can easily add, remove, and upgrade your dependencies.

# Installing wand

## Prerequisites
Wand requires [elixir](https://elixir-lang.org/install.html) before installing. You also need to have hex installed by running `mix local.hex`

## Installation
To install, we need to add wand_core, wand, and then make sure the binary is on your path.
Adding wand and wand_core is simple. Just open a terminal and paste the following line in:
`mix archive.install hex wand_core --force && mix escript.install hex wand --force`

Once that is done, then wand is successfully installed on your system to `~/.mix/escripts`. You can verify that by running `~/.mix/escripts/wand` in the terminal. If successful, it should display the wand help information. It's a pain to type the full path every time, so it is suggested you add the directory to your path. Edit your `.bashrc` (or similar config file) to look something like this: `export PATH=$HOME/.mix/escripts:$PATH`. Then, restart your terminal, and run `which wand`. If that points to `~/.mix/escripts/wand`, then you're all set!

## Verify Installation
You can verify that wand was properly installed by typing `wand --version` to make sure wand is installed, and `wand core --version` to make sure that [wand_core](http://github.com/anilredshift/wand-core) is installed

### Usage
Get started by navigating to an existing elixir project and type `wand init`. This will generate a _wand.json_ file. You should check this file into your source control. From now on, your dependencies are controlled by _wand.json_ in conjunction with your _mix.lock_ file. Let's take a quick look at an example wand.json file:
```
{
  "version": "1.0.0",
  "dependencies": {
    "ex_doc": [">= 0.0.0",{"only":":dev"}],
    "excoveralls": ["~> 0.9.1",{"only":":test"}],
    "junit_formatter": ["~> 2.2",{"only":":test"}],
    "mox": ["~> 0.3.2",{"only":":test"}]
  }
}
```
The dependencies key should look very similar to your deps() inside of mix.exs. The pattern of each entry is either `name: requirement` or `name: [requirement, {opts}]`. The options should look familiar, they exactly match the existing [allowed options](https://hexdocs.pm/mix/Mix.Tasks.Deps.html). It's possible to edit this by hand, but it's better to use the wand cli:

## CLI commands
```
add         Add dependencies to your project
core        Manage the related wand_core package
help        Get detailed help
init        Initialize wand for a project
outdated    List packages that are out of date
remove      Remove dependencies from your project
upgrade     Upgrade a dependency in your project
version     Get the version of wand installed on the system

Options

--verbose   Detailed help for every command
--?         Same as --verbose
```

Detailed help is available by typing wand help [command] or by clicking on the links below:

* `Wand.CLI.Commands.Add`
* `Wand.CLI.Commands.Core`
* `Wand.CLI.Commands.Help`
* `Wand.CLI.Commands.Init`
* `Wand.CLI.Commands.Outdated`
* `Wand.CLI.Commands.Remove`
* `Wand.CLI.Commands.Upgrade`
* `Wand.CLI.Commands.Version`

## CircleCI and other CI.
You need to have the wand_core archive added to your image before running mix deps.get. The command for CircleCI would be:
`- run: mix archive.install hex wand_core --force`

## Publishing packages
You need to make sure that wand.json is uploaded to hex when publishing packages. This is accomplished by modifying the `package` key in your `mix.exs` file as follows:
```elixir
def project do
  [
    package: [
      files: ["mix.exs", "wand.json", "lib"] # etc add more files as needed
    ]
  ]
end
```
This will ensure that wand.json is uploaded along with your other files

## Local development
1. `mix archive.install hex wand_core --force`
2. `git clone git@github.com:AnilRedshift/wand.git`
3. `cd wand`
4. `mix deps.get`
5. `mix test`

## Integration tests
Wand also has tests which run the wand binary against real mix projects to verify their behavior. You can run these with `mix test --include external`

Additionally, you can see the CLI output of each command with `mix test --include external --include print`


# Build status
[![Coverage Status](https://coveralls.io/repos/github/AnilRedshift/wand/badge.svg?branch=master)](https://coveralls.io/github/AnilRedshift/wand?branch=master)[![CircleCI branch](https://img.shields.io/circleci/project/github/AnilRedshift/wand/master.svg)](circle)
