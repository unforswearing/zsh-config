################
export CLICOLOR=1
export EDITOR="hx" #"nvim" #"micro"
export GPG_TTY=$TTY
# https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
export HISTFILE="$HOME/.history"
export HISTSIZE=50000000
export SAVEHIST=10000000
export HISTTIMEFORMAT='%F %T '
export HISTIGNORE="exit:bg:fg:history:clear:reload"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LSCOLORS=ExFxBxDxCxegedabagacad
export PAGER="more"
export PS2="  "
export PERIOD=90000
export SHELLFUNCS_DEFAULT_SHELL="/opt/local/bin/bash"
export VISUAL="$EDITOR"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
################
export EXA_PERMISSIONS
export EXA_DEFAULT_OPTIONS="--color auto --all --group-directories-first "
EXA_DEFAULT_OPTIONS+="--long --header --modified --sort=name "
EXA_DEFAULT_OPTIONS+="--git --time-style=iso --classify --no-permissions --no-user"
export FZF_DEFAULT_OPTS="--border --exact --layout=reverse --no-bold --cycle"
export GOPATH="$HOME/go"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=0
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor root line)

