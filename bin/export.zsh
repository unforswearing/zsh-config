################
export CLICOLOR=1
export EDITOR="hx" #"nvim" #"micro"
export GPG_TTY=$TTY
# https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
export HISTFILE="$HOME/.history"
export HISTSIZE=50000000
export SAVEHIST=10000000
export HISTTIMEFORMAT='%F %T '
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
################
export RE_ALPHA="[aA-zZ]"
export RE_STRING="([aA-zZ]|[0-9])+"
export RE_WORD="\w"
export RE_NUMBER="^[0-9]+$"
export RE_NUMERIC="^[0-9]+$"
export RE_NEWLINE="\n"
export RE_SPACE=" "
export RE_TAB="\t"
export RE_WHITESPACE="\s"
export POSIX_UPPER="[:upper:]"
export POSIX_LOWER="[:lower:]"
export POSIX_ALPHA="[:alpha:]"
export POSIX_DIGIT="[:digit:]"
export POSIX_ALNUM="[:alnum:]"
export POSIX_PUNCT="[:punct:]"
export POSIX_SPACE="[:space:]"
export POSIX_WORD="[:word:]"
