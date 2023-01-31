# Zsh Config

My overly complicated z-shell configuration files. This project was created as a way to understand the inner-workings of zsh without relying on the popular frameworks. Additionally, I wanted to take advantage of the extensive cusomtization zsh offers by creating a light DSL / command syntax atop the standard z-shell builtins (see `fs.zsh`, `math.zsh`, `string.zsh`, and `syntax.zsh`). And for even more fun, I added a lightweight `sqlite` key-value store (`zdb.zsh`).

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

The `zsh-config/etc` directory contains zsh user-contributed functions, found [here](). I only use a few:

- reporter
- zrecompile
- ztodo

## `zsh-config/plugin`

Zsh plugins that would typically be installed via framework. See directory for details of each item. 