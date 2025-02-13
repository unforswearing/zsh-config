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
# rabs == "run abs"
# ex. `rabs "env('ZSH_CONFIG_DIR')"`
# abs: https://www.abs-lang.org/
ABS_DIR="$ZSH_BIN_DIR/abs/"
function rabs() { "$ABS_DIR/rabs.abs" "${@}"; }
## ---------------------------------------------
source "${ZSH_BIN_DIR}/zsh/req.zsh"
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
  # Etc
  alias finder='open .'
  alias ls='ls -a'
  alias purj='sudo purge && sudo purge && sudo purge'
  alias pip='pip3'
  alias edit='micro' #'nvim'
  alias c="pbcopy"
  alias p="pbpaste"
  alias cf='pbpaste|pbcopy'
  alias rm='rm -i'
  alias cp='cp -i'
  alias rmf='sudo rm -rf'
  alias plux='chmod +x'
  alias namesingle='vidir'
  alias sed='/usr/local/bin/gsed'
  alias togglewifi='networksetup -setairportpower en1 off && sleep 3 && networksetup -setairportpower en1 on'
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
}
{
  # https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
  export HISTFILE="$HOME/.history"
  export HISTSIZE=50000000
  export SAVEHIST=10000000
  export HISTTIMEFORMAT='%F %T '
  export HISTIGNORE="exit:bg:fg:history:clear:reload"
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
req help
 # run-help / help
(($ + alaises[run - help])) && unalias run-help >/dev/null 2>&1
autoload -Uz run-help
## ---------------------------------------------
function mini() {
  ssh alvin@192.168.0.150
}
function prev() {
  cd "${PREV}" || cd < "${HOME}/.zsh_reload.txt"
}
function reload() {
  source "${ZSH_CONFIG_DIR}/.zshrc" || exec zsh
}
function async() {
  ({ eval "$@"; } &) >/dev/null 2>&1
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
# hot reload recently updated files w/o reloading the entire env
function swap() {
  unsetopt warn_create_global

  hash -r
  # save the current dir
  pwd >|"$HOME/.zsh_reload.txt"

  # attemt to hot reload config files
  local fd_options=(
    --type file
    --absolute-path
    --max-depth=1
    --threads=2
    --change-newer-than 1min
  )
  # source bin files
  fd --base-directory ~/zsh-config/bin/zsh ${fd_options[@]} |
    # source all recently updated files
    while read item; do print "sourcing ${item}"; source "${item}"; done
  # source usr files
  # fd --base-directory ~/zsh-config/zsh ${fd_options[@]} |
  #   # source all recently updated files
  #   while read item; do print "sourcing ${item}"; source "${item}"; done

  source "/Users/unforswearing/zsh-config/.zshrc"
  setopt warn_create_global
}
function cpl() {
  req "pee"

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
  req nu
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
  *) libutil:error.option "$opt" ;;
  esac
}
function memory() { sysinfo memory; }
## ---------------------------------------------
# BOTTOM: hooks / builtin event handlers
## the following are not used:
# - command_not_found_handler() {;}
# preexec() {
  # add typechecking here via abs script
  # the $1 arg holds the full text entered at the command line
# }
# chpwd() {
#  if [[ $(pwd) == "/Users/unforswearing/zsh-config" ]]; then
#    echo "you're in it now, bb"
#  fi
# }
precmd() {

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
  export LAST=${last}
}
periodic() {
  # abs bin/abs/maintain.abs
  #
  # MOVE THESE COMMANDS TO zsh_config.abs
  # --------------------------------------
  # update hosts file from stevenblack/hosts
  ({
    python3 "${ZSH_USR_DIR}/hosts.py";
  }&) >|/dev/null 2>&1
  # --------------------------------------
  # remove all .DS_Store files (not sure if working)
  # ({
  #  find . -name '*.DS_Store' -type f -ls -delete
  # }&) >|/dev/null 2>&1
}
## ---------------------------------------------
# cd $(cat $HOME/.zsh_reload.txt) || cd $HOME
cd "$PREV" || cd "$HOME"
## ---------------------------------------------
# uses the `debug` function, see utils.zsh
# do not clear output if debug is true, otherwise clear=clear
test $DEBUG || eval $CLEAR
## ---------------------------------------------
({
  # MOVE THESE COPY COMMANDS TO zsh_config.abs
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
# watch for new feed entries for unforswearing.com/feed
# old code deleted -- whether this is needed remains to be seen.
## ---------------------------------------------
# LOAD COMPLETIONS LAST
autoload compinit
autoload bashcompinit
eval "$(direnv hook zsh)"
## ---------------------------------------------
setopt warn_create_global
## ---------------------------------------------
