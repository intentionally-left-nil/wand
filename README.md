# Wand [![Hex version badge](https://img.shields.io/hexpm/v/wand.svg)](https://hex.pm/packages/wand)

**wand** is a dependency manager that uses a _wand.json_ file to replace your deps() in mix.exs. This allows you to add, remove, and upgrade packages easily using the wand cli.

## Quickstart
**To install**: `mix archive.install hex wand --force && mix archive.install hex wand_core --force`

**To use wand in a project**: `wand init`

**Add a dependency**: `wand add poison`

**Remove a dependency**: `wand remove poison`

**Upgrade a dependency**: `wand upgrade poison --latest`

**help**: `wand --help`

# Installing wand

## Prerequisites
Wand requires [elixir](https://elixir-lang.org/install.html) before installing. You also need to have hex installed by running `mix local.hex`

## Installation
`mix archive.install hex wand --force && mix archive.install hex wand_core --force`

After installation, you need to add the escript directory to your `PATH`. This is usually `~/.mix/escripts`

You can verify this by typing in `mix escript` to see what path to add.

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

## Local development
1. `git clone git@github.com:AnilRedshift/wand.git`
2. `cd wand`
3. `mix deps.get`
4. `mix test`


# Build status
[![Coverage Status](https://coveralls.io/repos/github/AnilRedshift/wand/badge.svg?branch=master)](https://coveralls.io/github/AnilRedshift/wand?branch=master)[![CircleCI branch](https://img.shields.io/circleci/project/github/AnilRedshift/wand/master.svg)](circle)
