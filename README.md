# Zsh Config

My overly complicated z-shell configuration files.

## Changes 12/12/2023

Havent thought about this in a while, want to revisit with a more simple approach:

- Stop using Lua/Teal/Whatever
- Add a build step to combine everything into a single file.
  - build can run manually for testing new stuff
  - build will be run automatically when running exec zsh
- Add backup command to archive things from the home folder
  - p10k theme
  - hosts.py
  - etc?
- Reduce the amount of stuff I will never use
  - zsh db stuff
  - etc?
- Simplify zshrc file
- Create tests

## Changes, 5/7/2023

Much of the zsh.dsl functionality will be replaced with lua / [teal](https://github.com/teal-language/tl) [types](https://pdesaulniers.github.io/tl/tutorial), [luash](https://github.com/zserge/luash), [ansicolors](https://github.com/kikito/ansicolors.lua), and [luafilesystem](https://github.com/lunarmodules/luafilesystem).

The idea is to bring different 'plumbing' and types to zsh with a new language, however writing a new language isn't necessary. See ~cloud/Notes/language.sl for the original specification.

All `teal` scripts should include the following header:

```lua
colors = require("ansicolors")
require("luafilesystem")
require("sh")
```

Anything that is not interactive can be rewritten in teal. Focus on rewriting the following source files from `/bin`

- conv.zsh
- dsl.zsh
- fs.zsh
  - files()
  - dir()
- utils.zsh
  - sys()
  - zc()
  - external()
  - update()...
- zdb.zsh (maybe)

Resources

- <https://learnxinyminutes.com/docs/lua/>
- <https://www.lua.org/pil/>
- <http://lua-users.org/wiki/>
  - <http://lua-users.org/wiki/StringLibraryTutorial>
  - <http://lua-users.org/wiki/TableLibraryTutorial>
  - <http://lua-users.org/wiki/IoLibraryTutorial>
  - <http://lua-users.org/wiki/OsLibraryTutorial>
- <https://github.com/teal-language/tl>
- <https://pdesaulniers.github.io/tl/tutorial.html>
- <https://github.com/zserge/luash>
- <https://github.com/lunarmodules/luafilesystem>

---

> NOTE: The docs below need to be updated

This config was created as a way to understand the inner-workings of zsh without relying on the popular frameworks. I also wanted to take advantage of other shells and programming languages throughout my environment, so you will see references to commands run with python and other languages, as well as functions that use nushell to interact with my system. The customization options in `zsh` create a DSL of sorts that includes string and math objects, as well as some filesystem and database functions.

Below is a list of files and folders along with a brief description of their contents and purpose.

## `.zshenv`

Setting the $PATH environment variable

## `.zshrc`

Soucing files, some basic commands, and setting the builtin `precmd` and `periodic` functions.

- Set a `DEBUG` environment variable, which can be toggled with the `debug` function
- Create environment variables for configuration directories
- Source the `zsh-defer` and `colors` plugins
- Source files from the `/bin` directory
- Source `powerlevel10k` theme
- Declare `precmd` and `periodic` hook functions
- Navigate to the directory listed in `reload_dir.txt`

## `zsh-config/bin`

Startup files for the interactive shell. These files are sourced via `.zshrc`.

- alias.zsh
- config.zsh
- export.zsh
- conv.zsh
- exprt.zsh
- fs.zsh
- utils.zsh
- zdb.zsh

### `zsh-config/bin/dsl`

An attempt to create an alternate syntax and a "standard library" for zsh.

With the exception of dsl.zsh, all dsl files can be loaded via `use::<filename>`

- dsl.zsh
  - loaded via zshrc
- filepath.zsh
- mathnum.zsh
- pairs.zsh
- string.zsh

## `zsh-config/etc`

The `zsh-config/etc` directory contains zsh user-contributed functions, found at [zsh-users/zsh](https://github.com/zsh-users/zsh). I only use a few:

- reporter
- zed
- zrecompile
- ztodo

## `zsh-config/plugin`

Zsh plugins that would typically be installed via framework. See directory for details of each item.

## `zsh-config/usr`

User scripts not necessarily written in Z-shell. Currently includes

- hosts.py

Automated updates of [StevenBlack/hosts](https://github.com/StevenBlack/hosts) directly to `/etc/hosts`

- [lnks.bash](https://github.com/unforswearing/lnks)

A script for printing / saving Google Chrome urls from the terminal on MacOS.
