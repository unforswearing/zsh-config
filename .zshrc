#!/usr/local/bin/zsh
# ##################################################################
# Zsh Configuration Outline
# `$HOME/.zprofile`:
#   - $ZDOTDIR is set to $HOME/zsh-config
# `~zconf/.zshenv`:
#   - edit $PATH in `~zconf/.zshenv`
# #################################################################
# return if the shell is not interactive (the commands would have no use)
trap "exec zsh" USR1 && [[ $- != *i* ]] && [ ! -t 0 ] && return
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
  alias edit='micro' #'nvim'
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
function prev() {
  cd "${PREV}" || cd < "${HOME}/.zsh_reload.txt"
}
function reload() {
  source "${ZSH_CONFIG_DIR}/.zshrc" || exec zsh
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
function color() {
  local red="\033[31m"
  local green="\033[32m"
  local yellow="\033[33m"
  local blue="\033[34m"
  local reset="\033[39m"
  local black="\033[30m"
  local white="\033[37m"
  local magenta="\033[35m"
  local cyan="\033[36m"
  local opt="$1"
  shift
  case "$opt" in
    red) print "${red}$@${reset}" ;;
    green) print "${green}$@${reset}" ;;
    yellow) print "${yellow}$@${reset}" ;;
    blue) print "${blue}$@${reset}" ;;
    black) print "${black}$@${reset}" ;;
    white) print "${white}$@${reset}" ;;
    magenta) print "${magenta}$@${reset}" ;;
    cyan) print "${cyan}$@${reset}" ;;
    help) print "colors <red|green|yellow|blue|black|magenta|cyan> string" ;;
  esac
}
# load external functions from `functions.json`
#   using `bin/ruby/functions.rb`
function loadf() {
  use use
  eval "$(${ZSH_BIN_DIR}/ruby/functions.rb get ${1})";
}
function loadf.list() {
  ${ZSH_BIN_DIR}/ruby/functions.rb list-all-functions;
}
function loadf.select() {
  loadf "$(loadf.list | fzf)"
}
# example:
#   use ls
#   use zyx.null -> error
function use() {
  unsetopt warn_create_global && \
    caller="$0" && arg="$1" && \
    setopt warn_create_global

  function success() { color green "$caller: '$arg' loaded"; }
  function failure() { color red "$caller: ${1}"; }

  if [[ "$1" == ":mute" ]] && {
    function success() { :; }
    shift
  }

  case "$1" in
  ""|" "*) failure "Please enter a command or filename" ;;
  *)
    local comm="$(command -v $1)"
    if [[ $comm ]]; then
      true
    else
      color red "$0: command '$1' not found in current environment"; false
    fi
    ;;
  esac
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
## ---------------------------------------------
# BOTTOM: hooks / builtin event handlers
## the following are not used:
# - command_not_found_handler() {;}
# preexec() {
# the $1 arg holds the full text entered at the command line
# }
# chpwd() {
#  if [[ $(pwd) == "/Users/unforswearing/zsh-config" ]]; then
#    echo "you're in it now, bb"
#  fi
# }
function precmd() {
  # save the current dir to auto-cd if iterm crashes
  ({
    pwd >|"$HOME/.zsh_reload.txt"
  }&) >|/dev/null 2>&1
  export PREV="$(pwd)"
  # --------------------------------------
  local last="$(
    history |
      gtail -n 1 |
      awk '{first=$1; $1=""; print $0;}' |
      sed 's/\"//g'
  )"
  export LAST="${last}"
}
function periodic() {
  # --------------------------------------
  # update hosts file from stevenblack/hosts
  ({
    # getpass = () => security find-generic-password -w -s "${key}" -a "$(whoami)";
    getpass ".zshrc" | \
    sudo -S /usr/local/bin/python3.11 "${ZSH_BIN_DIR}/python/hosts.py"
  }&) >|/dev/null 2>&1
  # --------------------------------------
  # remove all .DS_Store files (not sure if working)
  # ({
  #  find . -name '*.DS_Store' -type f -ls -delete
  # }&) >|/dev/null 2>&1
}
## ---------------------------------------------
({
  # backup .zshrc and .zshenv
  # zsh-config/.zshrc is the main version of the file
  \cp "${ZSH_CONFIG_DIR}/.zshrc" "${ZSH_CONFIG_DIR}/dotbkp";
  # bin/python/hosts.py is the main version of the file
  \cp "${ZSH_BIN_DIR}/python/hosts.py" "${ZSH_CONFIG_DIR}/dotbkp";
  \cp "${HOME}/.zshenv" "${ZSH_CONFIG_DIR}/dotbkp";
  # source zsh-config/.zshrc from $HOME/.zshrc
  echo "source $0" >| "${HOME}/.zshrc";
}&) >|/dev/null 2>&1
## ---------------------------------------------
# cd $(cat $HOME/.zsh_reload.txt) || cd $HOME
cd "$PREV" || cd "$HOME"
## ---------------------------------------------
# uses the `debug` function, see utils.zsh
# do not clear output if debug is true, otherwise clear=clear
test $DEBUG || eval $CLEAR
## ---------------------------------------------
setopt warn_create_global
## ---------------------------------------------
# LOAD COMPLETIONS LAST
autoload compinit
autoload bashcompinit
eval "$(direnv hook zsh)"
## ---------------------------------------------
cat "${0}" | /usr/bin/base64 >| "${ZSH_CONFIG_DIR}/.zshrc.b64"