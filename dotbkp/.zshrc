#!/usr/local/bin/zsh
# ##################################################################
# Zsh Configuration Outline
# `$HOME/.zprofile`:
#   - $ZDOTDIR is set to $HOME/zsh-config
# `~zconf/.zshenv`:
#   - edit $PATH in `~zconf/.zshenv`
#   - add API keys to `~zconf/.zshenv`
# #################################################################
## ---------------------------------------------
setopt allexport
unsetopt monitor
unsetopt warn_create_global
## ---------------------------------------------
eval "$(starship init zsh)"
## ---------------------------------------------
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
## ---------------------------------------------
# https://github.com/unforswearing/aliaser
export ALIASER_SOURCE="${ZSH_BIN_DIR}/bash/aliaser.sh"
source "${ALIASER_SOURCE}"
# ---
source "$ZSH_CONFIG_DIR/debug.zsh"
source "$ZSH_CONFIG_DIR/pass.zsh"
source "$ZSH_CONFIG_DIR/sysinfo.zsh"
## ---------------------------------------------
{
  ## ---------------------------------------------
  # suffix aliases
  alias -s git='git clone'
  ## ---------------------------------------------
  # -g == global alias. global as in expands anywhere on the current line
  ## ---------------------------------------------
  # standard aliases
  # Languages
  alias irb='/usr/local/opt/ruby/bin/irb'
  alias rake='/usr/local/opt/ruby/bin/rake'
  alias ruby='/usr/local/opt/ruby/bin/ruby'
  alias python='/usr/local/bin/python3'
  alias pip='/usr/local/bin/pip3'
  alias sed='/usr/local/bin/gsed'
  # Etc
  alias ls='\ls -a'
  alias rm='\rm -i'
  alias cp='\cp -i'
}
{
  export STARSHIP_CONFIG="${ZSH_CONFIG_DIR}/settings/starship.toml"
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
  export FZF_DEFAULT_OPTS="--border --exact --layout=reverse --no-bold --cycle --height=80"
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
  export HISTIGNORE="edit:exit:bg:fg:clear:reload:hist"
  setopt append_history
  setopt cshjunkie_history
  setopt hist_expire_dups_first
  setopt hist_lex_words
  setopt hist_reduce_blanks
  setopt inc_append_history
  setopt share_history
  setopt HIST_IGNORE_DUPS
  setopt HIST_IGNORE_ALL_DUPS
  setopt HIST_IGNORE_SPACE
  setopt HIST_FIND_NO_DUPS
  setopt HIST_SAVE_NO_DUPS
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
  source "$ZSH_PLUGIN_DIR/zsh-fzf-history-search/zsh-fzf-history-search.zsh"
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
#  FUNCTIONS
## ---------------------------------------------
# manage the functions.json file using bin/ruby/functions.rb
# ---
# f add <name> <"cmd1" "cmd2" "cmd3 | cmd4" ...>
# f get <name>
# f serialize-function <name>
# f verify-function <name>
# f list-all-functions
# ---
# note: use `loadf` to load a function into the current env.
#       use `loadf unset` to remove a function from the env.
function f() {
  "${ZSH_BIN_DIR}/ruby/functions.rb" "$@"
}
# if function "name" is currently in the zsh env, serialize and add to functions.json
function addf() {
  f serialize-and-add "$(whence -f ${1})"
}
# load external functions from `functions.json` using `bin/ruby/functions.rb`
function loadf() {
  if [[ "$1" == "unset" ]]; then unset -f "${2}"; return $?; fi;
  eval "$(${ZSH_BIN_DIR}/ruby/functions.rb get ${1})";
}
function import() { loadf "$@" ; }
# ---
# Load functions from `$ZSH_CONFIG_DIR/functions.json`
(function {
  loadf c; # alias for pbcopy
  loadf cf; # clear extraneous formatting on clipboard text
  loadf clearhosts; # remove all entries from /etc/hosts
  loadf copy; # copy var, file contents, or text
  loadf cpl; # copy the last command to the clipbaord
  loadf edit; # edit config files or <filename>
  loadf green; # print green text
  loadf memory; # display current memory stats
  loadf modified; # show when <file> was last modified
  loadf p; # alias for pbpaste
  loadf plux; # alias for chmod +x <file>
  loadf prev; # navigate to the previous directory
  loadf purj; # purge system memory
  loadf py; # run a python command: py "print('hello from python')"
  loadf rb; # run a ruby command: rb "puts 'hello from ruby'"
  loadf red; # print red text
  loadf reload; # reload the zsh environment to apply changes
  loadf s; # search and navigate to recent directories
  loadf updatehosts; # update /etc/hosts with StevenBlack/hosts
  loadf use; # alias for command -v <cmd_name>
  loadf yellow; # print yellow text
} >|/dev/null 2>&1) &
## ---------------------------------------------
# BOTTOM: hooks / builtin event handlers
# ---
# function periodic() {
#  # not sure if the periodic function actually works...
# }
# function preexec() {
#  # the $1 arg holds the full text entered at the command line
# }
function command_not_found_handler() {
  # The ruby commands below will allow "@" to act as
  # an alias for "echo" to print the text that follows, eg:
  # '@words to echo | sd "to echo" "were echoed" -> "words were echoed"'
  # Note: this will print variable values but will not execute commands.
  echo "$@" | rb "strarg = ARGF.read
    pipearg = strarg.split('')
    firstchar = pipearg[0]
    if firstchar == '@'
      pipearg.shift()
      puts pipearg.join().strip
    else
      puts \"[zsh] command not found: #{strarg}\"
    end"
}
function chpwd() {
  # eventually use like direnv and load folder-specific shell functions / commands
  # todo: load any utilities that will help with creating my zsh config below
  if [[ $(pwd) == "/Users/unforswearing/zsh-config" ]]; then
    # load utilities here...
    echo "configuration"
  fi
}
function precmd() {
  unsetopt warn_create_global
  local last="$(
    history | gtail -n 1 | awk '{first=$1; $1=""; print $0;}' | sed 's/\"//g'
  )"
  export LAST="${last}"
}
## ---------------------------------------------
# cd $(cat $HOME/.zsh_reload.txt) || cd $HOME
cd "$PREV" || cd "$HOME"
## ---------------------------------------------
# DEBUG and CLEAR can be set by using the `debug` function, see debug.zsh
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
# eval "$(direnv hook zsh)"
## ---------------------------------------------
# Backup .zshrc and .zshenv to $ZSH_CONFIG_DIR/dotbkp
loadf bkpconfig && bkpconfig
