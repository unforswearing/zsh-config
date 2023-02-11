# Zsh Config

My overly complicated z-shell configuration files. This project was created as a way to understand the inner-workings of zsh without relying on the popular frameworks. Additionally, I wanted to take advantage of the extensive customization zsh offers by creating a light DSL / command syntax atop the standard z-shell builtins (see `fs.zsh`, `math.zsh`, `string.zsh`, and `syntax.zsh`). And for even more fun, I added a lightweight `sqlite` key-value store (`zdb.zsh`).

Below is a list of files and a brief description of what they do. 

## `.zshenv`

Store the system $PATH as an array.

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