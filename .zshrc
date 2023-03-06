#########################################################################
# edit PATH in zshenv
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
fpath+=("/usr/share/zsh")
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
source "${ZSH_PLUGIN_DIR}/romkatv/zsh-defer/zsh-defer.plugin.zsh"
source "${ZSH_PLUGIN_DIR}/Tarrasch/zsh-colors/colors.plugin.zsh"
fd -t f --max-depth 1 . "$ZSH_BIN_DIR" | while read _config_file_; do
  local shortname="$(basename $_config_file_)"
  source "$_config_file_" && {
    green "using: $shortname"
  } || {
    red "failed: $shortname"
  }
done
##########################################################################
source ~/powerlevel10k/powerlevel10k.zsh-theme
source ~/.p10k.zsh
##########################################################################
source "${ZSH_USR_DIR}/lnks.bash"
source "${ZSH_USR_DIR}/marks.bash"
##########################################################################
source "${ZSH_BIN_DIR}/dsl/dsl.zsh"
##########################################################################
# BOTTOM -------------------------------------------------------------- ::
####### hooks / builtin event handlers
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
        sed 's/"//g'
    )"
    sqlite3 /Users/unforswearing/zsh_history.db "insert into history (val) values (\"$prev\")" 
    # >|/dev/null 2>&1
  })
}
periodic() {
  ({ python3 "${ZSH_USR_DIR}/hosts.py"; } &) >|/dev/null 2>&1
  ({ port selfupdate; } &) >|/dev/null 2>&1
  # ({ tldr --update; } &) >|/dev/null 2>&1
  ({ fd -H '^\.DS_Store$' -tf -X rm; } &) >|/dev/null 2>&1
}
##########################################################################
# update path in db
# db put "path" "${PATH}"
cd $(cat $HOME/.zsh_reload.txt) || cd $HOME
test $DEBUG == true || eval $CLEAR

# -------------------------- #
# - LOAD COMPLETIONS LAST -  #
# -------------------------- #

autoload -U compinit && compinit
