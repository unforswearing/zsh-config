# Zsh Config

My overly complicated z-shell configuration files. 

This project was created as a way to understand the inner-workings of zsh without relying on the popular frameworks. I also wanted to take advantage of other shells and programming languages throughout my environment, so you will see references to commands run with python and other languages, as well as functions that use nushell to interact with my system. 

Finally, I used the customization options in `zsh` to create a DSL of sorts that includes string and math objects, as well as some filesystem and database functions.

Below is a list of files and folders along with a brief description of their contents and purpose. 

## `.zshenv`

<move these to the .zshrc section below>
- Set a `DEBUG` environment variable, which can be toggled with the `debug` function
- Create environment variables for configuration directories
- Source the `zsh-defer` and `colors` plugins
- Source files from the `/bin` directory
- Source `powerlevel10k` theme
- Declare `precmd` and `periodic` hook functions
- Navigate to the directory listed in `reload_dir.txt`

## `.zshrc`

Soucing files, some basic commands, and setting the builtin `precmd` and `periodic` functions. 


## `zsh-config/bin`

Startup files for the interactive shell. These files are sourced via `.zshrc`. 

- alias.zsh
- config.zsh
- export.zsh
- fs.zsh
- math.zsh
- string.zsh
- syntax.zsh
- system.zsh
- zdb.zsh

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
