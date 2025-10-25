#!/usr/local/bin/zsh
## ---------------------------------------------
# This file is "$HOME/zsh-config/.zshrc"
# ---
# => All settings, aliases, plugins, and zsh builtin functions are set in this file.
# => Zsh functions are stored in "$HOME/zsh-config/functions.json" and managed
#    using "$HOME/zsh-config/bin/ruby/functions.rb" and the "f", "loadf", and "addf"
#    helper functions set in this file (see "FUNCTIONS" section below).
# ---
# ** Edit $PATH in "$HOME/zsh-config/.zshenv"
# ** Add API keys to "$HOME/zsh-config/.zshenv"
## ---------------------------------------------
setopt allexport
unsetopt monitor
unsetopt warn_create_global
## ---------------------------------------------
eval "$(starship init zsh)"
## ---------------------------------------------
# brew install zsh-syntax-highlighting
source "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
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
## ---
# https://github.com/unforswearing/aliaser
export ALIASER_SOURCE="${ZSH_BIN_DIR}/bash/aliaser.sh"
source "${ALIASER_SOURCE}"
{
  ## ---------------------------------------------
  ## suffix aliases
  alias -s git='git clone'
  # -g == global alias. global as in expands anywhere on the current line
  # ---
  ## standard aliases
  # Note: aliases created on the fly should use aliaser.sh
  alias irb='/usr/local/opt/ruby/bin/irb'
  alias rake='/usr/local/opt/ruby/bin/rake'
  alias ruby='/usr/local/opt/ruby/bin/ruby'
  alias python='/usr/local/bin/python3'
  alias pip='/usr/local/bin/pip3'
  alias sed='/usr/local/bin/gsed'
  alias c='pbcopy'
  alias p='pbpaste'
  alias cf='pbpaste|pbcopy'
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
# ---
# Zsh helpers to manage the `$ZSH_CONFIG_DIR/functions.json` file
# using `$ZSH_CONFIG_DIR/bin/ruby/functions.rb`
# ---
function f() {
  "${ZSH_BIN_DIR}/ruby/functions.rb" "$@"
}
# if function "name" is currently in the zsh env, serialize and add to functions.json
function addf() {
  f serialize-and-add "$(whence -f ${1})"
}
# load external functions from `functions.json` using `bin/ruby/functions.rb`
function loadf() {
  eval "$(${ZSH_BIN_DIR}/ruby/functions.rb get ${1})";
}
function choosef() {
  local fname="$(f list-all-functions | fzf)"
  test ! -z "$fname" && {
    loadf "$fname"
    green "$fname loaded."
  } || red "no function selected."
}
function unsetf() {
  unset -f "${2}"
  return $?
}
# ---
# Load functions from `$ZSH_CONFIG_DIR/functions.json`
function {
  loadf cf; # clear extraneous formatting on clipboard text
  loadf clearhosts; # remove all entries from /etc/hosts
  loadf copy; # copy file contents / var values / text to the clipboard
  loadf cpl; # copy the last command to the clipboard
  loadf edit; # edit config files or <filename>
  loadf green; # print green text
  loadf memory; # display current memory stats
  loadf modified; # show when <file> was last modified
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
  # "pass.zsh" is a lib of functions for various password store / kv actions.
  source "$ZSH_BIN_DIR/zsh/pass.zsh"
}
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
  # The ruby commands below will (1) allow "@" to act as
  # an alias for "echo" to print the text that follows, eg:
  # '@words to echo | sd "to echo" "were echoed" -> "words were echoed"',
  # and (2) provide a warning if a cmd name is an unloaded functions.json item.
  # Note: (1) will print variable values but will not execute commands.
  # Todo: For (2), try to dynamically load functions.json item instead of just warning.
  echo "$@" | rb "require 'json'
    strarg = ARGF.read
    pipearg = strarg.split('')
    cmd_arg = strarg.split(' ')
    firstchar = pipearg[0]
    if firstchar == '@'
      pipearg.shift()
      puts pipearg.join().strip
    else
      function_file = File.expand_path('~/zsh-config/functions.json')
      config_functions = JSON.parse(File.read(function_file))['functions']
      config_functions.sort.each do |name, body|
        if name == cmd_arg[0]
          puts \"[zsh] function '#{name}' is not loaded. run 'loadf #{name}'\"
          return
        end
      end
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
  export LAST="$(
    history | gtail -n 1 | awk '{first=$1; $1=""; print $0;}' | sed 's/\"//g'
  )"
}
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
## ---------------------------------------------
cd "$PREV" || cd "$HOME"
