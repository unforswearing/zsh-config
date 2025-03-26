<<<<<<< HEAD
# Log 

## Changes, 5/31/2023

Lua is set up to run scripts

instead of Lua for types, use Python. Including:

- typing: https://docs.python.org/3/library/typing.html
- mypy: https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html#cheat-sheet-py3

with these I do not have to use some weird / outdated / incompatible typed lua dialect like teal (cool, but requires type files and examples are non-existent), or luau (incompatible with MacOS < 10.12), or Terra (systems programming library that calls itself a language built onto Lua), and etc. 

## Changes, 5/23/2023

Moved contents of bin files to bin/stdlib.zsh, as sourcing loops became annoying.

these files include:

- util.zsh
- import.zsh
- require.zsh

## Changes, 5/21/2023

The original zshrc broke things so I backed out. Changes include

- not currently using ZDOTDIR
- using zshrc, zshenv, and zshconfig from $HOME
- sourcing items in zsh-config/bin from within zshrc
- teal will not be used
- there is still a possiblility for rewriting files in /zsh-config/usr in lua
- lua will be used for scripts using the following as a shell library
  - luash
  - stdlib.zsh
  - zsh-config/src/bin 
  - generate_binfile 
- all lua scripts will start with

```lua
require("sh")
color("red", "colors work")
```

## Changes, 5/7/2023
=======
# Zsh Config

My ~~overly~~ increasingly less complicated z-shell configuration files.

## Changelog

### Changes 2/13/25

This is extraordinarily annoying to maintain, and I do not use the shell in my main work. Looking to keep my shell use to audio / video things, text processing, project scripting, and occasional data stuff.

#### Some updates:

- All zsh configuration has been cut back. Aliases, exports, options, and functions all live in `.zshrc`
  - Other configuration files have been archived
- All `abs` code has been archived (unused)
- Reinstalled `homebrew` due to issues with my configuration. Slowly adding packages.

#### To Do:

- Need to reconfigure / fix / reinstall the zsh syntax highlighting so it works on my own aliases and functions
- Use Ruby for local scripting. I want to learn it anyway and it seems to be good for [shell scripting](https://lucasoshiro.github.io/posts-en/2024-06-17-ruby-shellscript/)
- Use Bash for project scripts.
- Use Zsh interactively.
  - Re-establish a subset of commands I regularly use and maintain them
- To Fix: Something is managing my Python environment which makes installing things really dumb.

### Changes 6/28

Move `Changes` from README.md to LOG.md.

- Using Zsh for interactive use exclusively
- Using abs (see [Changes 6/8](#changes-68)) to replace Zsh scripts and config
  - abs has the easiest way to run shell commands and the syntax is C/Python-like.
    the main selling point is using abs as a programmable shell command runner. see
    [`/bin/abs`](/bin/abs/) for examples, starting with [`/bin/abs/fp.abs`](/bin/abs/fp.abs).
- Restructured project to remove junk
  - Increasingly prefer scripts over interactive use these days
  - Will continue to remove much of the unused config.zsh settings
  - May eventually remove all plugins (including `p9k`)


### Changes 6/8

Ignore previous updates.

- Start using [`abs`](https://abs-lang.com) for scripts.
- ~~Finish `stdlib.zsh` and load into interactive shells by default.~~
  - Don't bother with `stdlib.zsh`, it was never used. It is archived.
- Make the file and folder changes in the `### Directory List` section below.

#### New Config Structure

The config dir will not have a separate language / syntax included. `stdlib` is for interactive use, not scripts. `abs` will be used for scripting, replacing the syntax I have been creating.

#### Directory List

```
zsh-config
  - archive
  - bin
    - zsh
      - color.zsh
      - help.zsh
      - replify.sh
        ...
    - abs
      - ...
    - python
      - hosts.py
      - ...
  - dotbkp
  - plugin
  - config.zsh
  - req.zsh
  - .zshenv
  - .zshrc
```

### Changes 6/1

-> Update::::::

#### Interactive

for use on the command line. basic variables and functions.

top-level files:

- .zshrc
- .zshenv
- hosts.py
- bin/config.zsh
- bin/req.zsh
  - req sources: usr/help.zsh and usr/replify.sh
- usr/color.zsh (must manually source, also exists in bin/stdlib.zsh)

#### Scripting

for writing more robust scripts that do more detailed shell tasks.

to use as a scripting addition / helper, source the following files:

- bin/req.zsh
- bin/stdlib.zsh
-

#### To Do

> create a better data structure

- make sure to seprate interactive code from scripting helpers
  - stdlib is a scripting helper, not interactive
    - separate the req command so it does not need to be required by .zshrc
    - move all interactive code from stdlib
    - eventaully use scripts in objects/ folder
  - maybe create a `scripting` folder, move all stdlib related code there
- try to reduce the size of config.zsh
- [x] merge usr/ files into stdlib
- [x] make stdlib a req module
- [x] remove other modules from req
  - only help and stdlib *(and replify)* will remain as modules
- in stdlib
  - [x] add color ~and replify~
  - [x] add alphanum
  -> NOTE: see bash experimentation on old laptop

Starting to work on this again, it is annoyingly complicated, still.

Make everything more simple!

- stop using the `req`  function for self made scripts, only use it to check if something is available in the path
- merge color, alphanum, etc from /usr into stdlib and archive usr folder
  -> the file tree wil look like

```
- config
  - archive
  - bin
    - config.zsh
    - req.zsh
    - stdlib.zsh
  - plugin
    - ...
  - .zshenv
  - .zshrc
  - hosts.py
  - pavs.zsh
  - README
  - codeworkspace
```

- try to simplify config.zsh
- other cleanup and reorg tasks.
- KEEP the DSL aspects of this configuration, though I hardly ever do scripting these days
  - maybe only load `config` and the zsh dotfiles by default
    -> and make the dsl stuff in stdlib as a loadable module: `req stdlib`

### Changes 12/12/2023

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

### 5/13/2023

Too much fiddling made me fuck up this configuration on the old laptop. Installed commands aren't recognized, and nothing really works. Rebuiding from scratch.

Making repo readonly. DO NOT PUSH TO THIS REPO FOR ANY REASON

### 5/7/2023
>>>>>>> 3c4e5536b9e029343ca620b87bda4fbbbdb81eec

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
<<<<<<< HEAD
- fs.zsh 
=======
- fs.zsh
>>>>>>> 3c4e5536b9e029343ca620b87bda4fbbbdb81eec
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

<<<<<<< HEAD
---
=======
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
>>>>>>> 3c4e5536b9e029343ca620b87bda4fbbbdb81eec
