#!/usr/local/bin/zsh
# ##################################################################
# Zsh Configuration Outline
# `$HOME/.zprofile`:
#   - $ZDOTDIR is set to $HOME/zsh-config
# `~zconf/.zshenv`:
#   - edit $PATH in `~zconf/.zshenv`
# #################################################################
# return if the shell is not interactive (the commands would have no use)
# trap "exec zsh" USR1 && [[ $- != *i* ]] && [ ! -t 0 ] && return
## ---------------------------------------------
setopt allexport
unsetopt monitor
unsetopt warn_create_global
## ---------------------------------------------
source ~/powerlevel10k/powerlevel10k.zsh-theme && source ~/.p10k.zsh
# brew install zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
## ---------------------------------------------
# stop vi mode from loading automatically
bindkey -e
## ---------------------------------------------
# generate ~/.zprofile if it does not exist and ZDOTDIR is unset
if [[ -z $ZDOTDIR ]] && [[ ! -e "$HOME/zsh-config" ]]; then
  print "export ZDOTDIR=$HOME/zsh-config" >"$HOME/.zprofile"
fi
## ---------------------------------------------
# export ALIAS=($(alias))
export ZSH_CONFIG_DIR="$HOME/zsh-config"
export ZSH_BIN_DIR="$ZSH_CONFIG_DIR/bin"
#
cat "$ZSH_CONFIG_DIR/.zshenv" >| "$HOME/.zshenv"
## ---------------------------------------------
# exports, hash, aliases, options, bindkey, import function, moving source files
{
  ## ---------------------------------------------
  # suffix aliases
  alias -s git='git clone'
  ## ---------------------------------------------
  # -g == global alias. global as in expands anywhere on the current line
  ## ---------------------------------------------
  # standard aliases
  # ---
  # Languages
  alias ruby='/usr/local/opt/ruby/bin/ruby'
  alias irb='/usr/local/opt/ruby/bin/irb'
  alias rake='/usr/local/opt/ruby/bin/rake'
  alias pip='/usr/local/bin/pip3'
  alias sed='/usr/local/bin/gsed'
  # Etc
  alias finder='open .'
  alias ls='\ls -a'
  # alias edit='micro' #'nvim'
  alias rm='\rm -i'
  alias cp='\cp -i'
}
{
  export CLICOLOR=1
  export EDITOR="micro" #"hx" #"nvim" #"micro"
  export GPG_TTY=$TTY
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  export LSCOLORS=ExFxBxDxCxegedabagacad
  export PAGER="more"
  export PS2=".."
  export PERIOD=90000
  export SHELLFUNCS_DEFAULT_SHELL="/opt/local/bin/bash"
  export VISUAL="$EDITOR"
  export XDG_CACHE_HOME="${HOME}/.cache"
  export XDG_CONFIG_HOME="${HOME}/.config"
  export FZF_DEFAULT_OPTS="--border --exact --layout=reverse --no-bold --cycle"
  export GOPATH="$HOME/go"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=0
  export PIP_BREAK_SYSTEM_PACKAGES=1
}
{
  # https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
  export HISTFILE="$HOME/.history"
  export HISTSIZE=50000000
  export SAVEHIST=10000000
  # history -i
  export HISTTIMEFORMAT='%d%%y-%H%M%S'
  export HISTIGNORE="exit:bg:fg:history:clear:reload:hist"
  setopt append_history
  setopt cshjunkie_history
  setopt hist_expire_dups_first
  setopt hist_lex_words
  setopt hist_reduce_blanks
  setopt inc_append_history
  setopt share_history
}
{
  # setopt
  setopt alwaystoend
  setopt auto_cd
  setopt automenu
  setopt bsd_echo
  setopt c_precedences
  setopt cdable_vars
  setopt cshjunkie_loops
  setopt function_argzero
  setopt interactive_comments
  setopt ksh_zero_subscript
  setopt local_loops
  setopt menucomplete
  setopt no_append_create
  setopt no_clobber
  setopt no_bare_glob_qual
  setopt no_nomatch
  setopt numeric_glob_sort
  setopt sh_word_split
  # UNSETOPT ----------------------------------------------- ::
  unsetopt ksh_glob
}
{
  export ZSH_PLUGIN_DIR="$ZSH_CONFIG_DIR/plugin"
  source "$ZSH_PLUGIN_DIR/fzf-zsh/fzf-zsh-plugin.plugin.zsh"
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
  source "$ZSH_PLUGIN_DIR/3v1n0/zsh-bash-completions-fallback/zsh-bash-completions-fallback.plugin.zsh"
}
{
  zstyle ':completion:*' use-cache yes
  zstyle ':completion:*' cache-path $ZSH_CACHE_DIR
  zstyle ':completion:*' fzf-search-display true
  zstyle ':chpwd:*' recent-dirs-default
  zstyle ':chpwd:*' recent-dirs-file
  zstyle recent-dirs-file ':chpwd:*' ${ZDOTDIR:-$HOME}/.chpwd-recent-dirs-${TTY##*/} +
  zstyle ':chpwd:*' recent-dirs-insert 'both'
  # complete 'cd -<tab>' with menu
  zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
  # insert all expansions for expand completer
  zstyle ':completion:*:expand:*' tag-order all-expansions
  zstyle ':completion:*:history-words' list false
  # activate menu
  zstyle ':completion:*:history-words' menu yes
  zstyle ':completion:*:matches' group 'yes'
  zstyle ':completion:*:options' description 'yes'
  zstyle ':completion:*' verbose true
}
## ---------------------------------------------
# run-help / help
(($ + aliases[run - help])) && unalias run-help >/dev/null 2>&1
autoload -Uz run-help
function help() { get-help "${@}"; }
## ---------------------------------------------
function addpass() {
  use security
  local key="${1}"; local value="${2}"
  security add-generic-password -a "$(whoami)" -s "${key}" -w "${value}"
}
function getpass() {
  use security
  local key="${1}"
  security find-generic-password -w -s "${key}" -a "$(whoami)"
}
function rmpass() {
  use security
  local key="${1}"
  security delete-generic-password -s "${key}" -a "$(whoami)"
}
function reload() {
  source "${ZSH_CONFIG_DIR}/.zshrc" || exec zsh
}
function prev() {
  cd "${PREV}" || cd < "${HOME}/.zsh_reload.txt"
}
function s() {
  local arg="$1"
  local dir=$({
    cat "$HOME/.zsh_reload_prev.txt";
    cat "$HOME/.zsh_reload_curr.txt";
    } | sort -u | fzf --wrap --query="$arg" --select-1
  );
  cd "${dir}" || cd "$PWD"
}
function purj() {
  use getpass
  getpass ".zshrc" | sudo -S purge >|/dev/null 2>&1
}
function debug() {
  case "${1}" in
  "t" | "true")
    # sed -i 's/local DEBUG=false/local DEBUG=true/' ~/.zshrc
    export DEBUG=true
    export CLEAR=
    ;;
  "f" | "false")
    # sed -i 's/local DEBUG=true/local DEBUG=false/' ~/.zshrc
    export DEBUG=false
    export CLEAR="clear"
    ;;
  *) print "${DEBUG}" ;;
  esac
}
function togglewifi() {
  networksetup -setairportpower en1 off
  sleep 3
  networksetup -setairportpower en1 on
}
function updatehosts() {
  use nu; use gstat;
  sudo nu -c 'http get "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts" | save --force /etc/hosts' && \
  echo "/etc/hosts updated: $(gstat -c '%y' /etc/hosts)"
}
function color() {
  local reset="\033[39m"

  function red() {
    local red="\033[31m"
    print "${red}$@${reset}"
  }
  function green() {
    local green="\033[32m"
    print "${green}$@${reset}"
  }
  function yellow() {
    local yellow="\033[33m"
    print "${yellow}$@${reset}"
  }
  function blue() {
    local blue="\033[34m"
    print "${blue}$@${reset}"
  }
  function black() {
    local black="\033[30m"
    print "${black}$@${reset}"
  }
  function white() {
    local white="\033[37m"
    print "${white}$@${reset}"
  }
  function magenta() {
    local magenta="\033[35m"
    print "${magenta}$@${reset}"
  }
  function cyan() {
    local cyan="\033[36m"
    print "${cyan}$@${reset}"
  }
  local opt="$1"
  case "$opt" in
    help|--help|-h) print "colors <red|green|yellow|blue|black|magenta|cyan> string" ;;
  esac
}
function edit() {
  case "${1}" in
    settings) "$EDITOR" "$HOME/.config/micro/settings.json" ;;
    bindings) "$EDITOR" "$HOME/.config/micro/bindings.json" ;;
    init) "$EDITOR" "$HOME/.config/micro/init.lua" ;;
    zshrc) "$EDITOR" "$ZSH_CONFIG_DIR/.zshrc" ;;
    zshenv) "$EDITOR" "$ZSH_CONFIG_DIR/.zshenv" ;;
    *) "$EDITOR" "${@}" ;;
  esac
}
# manage the functions.json file using bin/ruby/functions.rb
# ---
# f add <name> <"cmd1" "cmd2" "cmd3 | cmd4" ...>
# f get <name>
# f list-all-functions
# ---
# note: use `loadf` to load a function into the current env.
#       use `loadf unset` to remove a function from the env.
function f() {
  "${ZSH_BIN_DIR}/ruby/functions.rb" "$@"
}
# load external functions from `functions.json`
#   using `bin/ruby/functions.rb`
function loadf() {
  if [[ "$1" == "unset" ]]; then unset -f "${2}"; return $?; fi;
  eval "$(${ZSH_BIN_DIR}/ruby/functions.rb get ${1})";
}
# f get loadf > tmp.f && shellcheck --exclude=2148 --format=diff tmp.f | patch -p1 tmp.f
# loadf.test is made obsolete by `f verify-function`
# function loadf.test() {
#   local name="${1}"
#   /usr/local/bin/shellcheck \
#     --severity=warning \
#     --exclude=2148 \
#     --format=json <(f get "$name") | \
#         jq '.[].message'
# }
# example:
#   use ls
#   use zyx.null -> error
function use() {
  unsetopt warn_create_global && \
    caller="$0" && arg="$1" && \
    setopt warn_create_global

  function success() { color green "$caller: '$arg' loaded"; }
  function failure() { color red "$caller: $arg"; }

  if [[ "$1" == ":mute" ]] && {
    function success() { :; }
    shift
  }

  case "$1" in
  ""|" "*) failure "Please enter a command or filename" ;;
  *)
    local comm="$(command -v $1)"
    if [[ $comm ]]; then
      # success
      true
    else
      color red "$0: command '$1' not found in shell or functions.json"; false
    fi
    ;;
  esac
  caller=;arg=;
}
function cpl() {
  use "pee"

  OIFS="$IFS"
  IFS=$'\n\t'

  local comm=$(
    history | tail -n 1 | awk '{first=$1; $1=""; print $0;}'
  )

  echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"

  IFS="$OIFS"
}
function opts() {
  setopt ksh_option_print
  if [[ -z ${options[$1]} ]]; then
    # libutil:error.notfound "$1"
  else
    local optvalue=${options[$1]}
    print $optvalue
  fi
}
function sysinfo() {
  # libutil:argtest "$1"
  use nu
  case $1 in
  host) nu -c "sys|get host" ;;
  cpu) nu -c "sys|get cpu" ;;
  disks) nu -c "sys|get disks" ;;
  mem | memory)
    nu -c "{
        free: (sys|get mem|get free),
        used: (sys|get mem|get used),
        total: (sys|get mem|get total)
      }"
    ;;
  temp | temperature) nu -c "sys|get temp" ;;
  net | io) nu -c "sys|get net" ;;
  *) color red "'${1}' is not a valid option" ;;
  esac
}
function memory() { sysinfo memory; }
## ---------------------------------------------
loadf plux; loadf c; loadf p; loadf cf
color
## ---------------------------------------------
# BOTTOM: hooks / builtin event handlers
## the following are not used:
# - function command_not_found_handler() {;}
# function periodic() {
  # Not sure the periodic function ever worked, really.
  # Now running externally: hosts.rb (in Lingon.app)
# }
function preexec() {
  echo $CURR >>| "$HOME/.zsh_reload_curr.txt"
  export CURR="$(pwd)"
# the $1 arg holds the full text entered at the command line
}
function chpwd() {
  # use like direnv
  # when entering ~/zsh-config, load these:
  if [[ $(pwd) == "/Users/unforswearing/zsh-config" ]]; then
    use choosefile || loadf choosefile
    use fileman || loadf fileman
  fi
  echo $PREV >>| "$HOME/.zsh_reload_prev.txt"
  export PREV="$CURR"
}
function precmd() {
  ({ ; }&) >|/dev/null 2>&1
  # --------------------------------------
  local last="$(
    history |
      gtail -n 1 |
      awk '{first=$1; $1=""; print $0;}' |
      sed 's/\"//g'
  )"
  export LAST="${last}"
}
## ---------------------------------------------
({
  # backup .zshrc and .zshenv
  # zsh-config/.zshrc is the main version of the file
  \cp "${ZSH_CONFIG_DIR}/.zshrc" "${ZSH_CONFIG_DIR}/dotbkp";
  # bin/python/hosts.py is the main version of the file
  \cp "${ZSH_BIN_DIR}/ruby/hosts.rb" "${ZSH_CONFIG_DIR}/dotbkp";
  \cp "${HOME}/.zshenv" "${ZSH_CONFIG_DIR}/dotbkp";
  # source zsh-config/.zshrc from $HOME/.zshrc
  echo "source $0" >| "${HOME}/.zshrc";
}&) >|/dev/null 2>&1
## ---------------------------------------------
# cd $(cat $HOME/.zsh_reload.txt) || cd $HOME
cd "$PREV" || cd "$HOME"
## ---------------------------------------------
# uses the `debug` function, see utils.zsh
# do not clear output if debug is true, otherwise CLEAR=clear
test $DEBUG || eval $CLEAR
# if neither DEBUG nor CLEAR is set, set CLEAR=clear
{ [[ -n $CLEAR ]] || [[ -n $DEBUG ]] ; } || export CLEAR=clear
## ---------------------------------------------
setopt warn_create_global
## ---------------------------------------------
# LOAD COMPLETIONS LAST
autoload compinit
autoload bashcompinit
eval "$(direnv hook zsh)"
## ---------------------------------------------
# cat "${0}" | /usr/bin/base64 >| "${ZSH_CONFIG_DIR}/.zshrc.b64"
