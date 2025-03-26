# Zsh Config

Somewhat complicated `zsh` configuration scripts. The overall size of the usable 
configuration in this repository is actively shrinking. See [Archive](/archive/)
for a full history of settings, scripts, and dsl experiments which ultimately 
went unused. 

<<<<<<< HEAD
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
=======
- See [WORKFLOW.md](/WORKFLOW.md) to understand how this configuration is used.
- See [LOG.md](/LOG.md) for "rationale".
>>>>>>> 3c4e5536b9e029343ca620b87bda4fbbbdb81eec
