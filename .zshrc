# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi
##########################################################################
# source ~/powerlevel10k/powerlevel10k.zsh-theme
# source ~/.p10k.zsh
#########################################################################
# edit PATH in zshenv
#########################################################################
# autoload -U +X bashcompinit && bashcompinit
# autoload -U +X compinit && compinit
#########################################################################
local DEBUG=false
local CLEAR='clear' # or '' to stop clearing screen
########################################################################
# stop vi mode from loading automatically
bindkey -e
#########################################################################
trap "exec zsh" USR1
# return if the shell is not interactive (the commands would have no use)
[[ $- != *i* ]] && [ ! -t 0 ] && return
#########################################################################
# .zshrc and .zshenv are hardlinked to ~zsh-config 
# in the bin/config.zsh file
## ---------------------------------------------
export ZSH_CONFIG_DIR="$HOME/zsh-config"
export ZSH_PLUGIN_DIR="$ZSH_CONFIG_DIR/plugin"
export ZSH_BIN_DIR="$ZSH_CONFIG_DIR/bin"
export ZSH_ETC_DIR="$ZSH_CONFIG_DIR/etc"
export ZSH_USR_DIR="$ZSH_CONFIG_DIR/usr"
## ---------------------------------------------
source "${ZSH_PLUGIN_DIR}/Tarrasch/zsh-colors/colors.plugin.zsh"
source "${ZSH_PLUGIN_DIR}/romkatv/zsh-defer/zsh-defer.plugin.zsh"
fd -t f --max-depth 1 . "$ZSH_BIN_DIR" | while read _config_file_; do
  local shortname="$(basename $_config_file_)"
  source "$_config_file_" && {
    green "using: $shortname"
  } || {
    red "failed: $shortname"
  }
done
##########################################################################
source "${ZSH_BIN_DIR}/dsl/dsl.zsh"
# BOTTOM -------------------------------------------------------------- ::
##########################################################################
# -- hooks / builtin event handlers -- #
# --------------------------------------
# command_not_found_handler() {;}
# preexec() {;}
precmd() {
  # save the current dir to auto-cd if iterm crashes
  pwd >|"$HOME/.zsh_reload.txt" &
  db put "reload_dir" "$(pwd)" &
  # add history to (new) db for history file zsh_history.db
  ({
    local prev="$(
      history | \
        gtail -n 1 | \
        awk '{first=$1; $1=""; print $0;}' | \
        sed 's/\"//g'
    )"
    sqlite3 /Users/unforswearing/zsh_history.db \
      "insert into history (val) values (\"$prev\")" 
      # >|/dev/null 2>&1
  })
}
periodic() {
  # update hosts file from stevenblack/hosts
  (
    {
      python3 "${ZSH_USR_DIR}/hosts.py";
      db put hosts_file_updated "$(gdate '+%Y-%m-%dT%H:%M')";
    } &
  ) >|/dev/null 2>&1
  # try to update macports (not sure if working)
  (
    { 
      port selfupdate; 
      db put macports_updated "$(gdate '+%Y-%m-%dT%H:%M')";
    } &
  ) >|/dev/null 2>&1
  # update tldr (not really useful)
  # ({ tldr --update; } &) >|/dev/null 2>&1
  # remove all .DS_Store files (not sure if working)
  (
    { 
      fd -H '^\.DS_Store$' -tf -X rm; 
      db put rm_ds_store "$(gdate '+%Y-%m-%dT%H:%M')"
    } &
  ) >|/dev/null 2>&1
}
##########################################################################
# update path in db
# db put "path" "${PATH}"
cd $(cat $HOME/.zsh_reload.txt) || cd $HOME
test $DEBUG == true || eval $CLEAR

# --------------------------------------
# LOAD COMPLETIONS LAST
autoload -U compinit && compinit
# --------------------------------------
