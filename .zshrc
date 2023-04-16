## ---------------------------------------------
# `.zshrc` and `.zshenv` are hardlinked to $HOME from 
# ~zconf/bin/config.zsh. edit $PATH in ~zconf/.zshenv
## ---------------------------------------------
source ~/powerlevel10k/powerlevel10k.zsh-theme && source ~/.p10k.zsh
## ---------------------------------------------
# return if the shell is not interactive (the commands would have no use)
trap "exec zsh" USR1 && [[ $- != *i* ]] && [ ! -t 0 ] && return
## ---------------------------------------------
# stop vi mode from loading automatically
bindkey -e
## ---------------------------------------------
export ZSH_CONFIG_DIR="$HOME/zsh-config"
export ZSH_PLUGIN_DIR="$ZSH_CONFIG_DIR/plugin"
export ZSH_BIN_DIR="$ZSH_CONFIG_DIR/bin"
export ZSH_ETC_DIR="$ZSH_CONFIG_DIR/etc"
export ZSH_USR_DIR="$ZSH_CONFIG_DIR/usr"
## ---------------------------------------------
fd -t f --max-depth 1 . "$ZSH_BIN_DIR" | while read _config_file_; do
  local shortname="$(basename $_config_file_)"
  source "$_config_file_" || print "failed: $shortname"
done
## ---------------------------------------------
source "${ZSH_BIN_DIR}/dsl/dsl.zsh" && use ::dsl
## ---------------------------------------------
# BOTTOM: hooks / builtin event handlers 
## the folling are not used:
# - command_not_found_handler() {;}
# - preexec() {;}
precmd() {
  # save the current dir to auto-cd if iterm crashes
  pwd >|"$HOME/.zsh_reload.txt" &
  # --------------------------------------
  # if [[ $(db get reload_dir) -ne $(pwd) ]]; then 
  test "$(db get reload_dir)" != "$(pwd)" && {
    db put "previous_dir" "$(db get reload_dir)"
    db put "reload_dir" "$(pwd)" &  
  }
  # fi
  # --------------------------------------
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
  # --------------------------------------
  # update hosts file from stevenblack/hosts
  (
    {
      python3 "${ZSH_USR_DIR}/hosts.py";
      db put hosts_file_updated "$(gdate '+%Y-%m-%dT%H:%M')";
    } &
  ) >|/dev/null 2>&1
  # --------------------------------------
  # remove all .DS_Store files (not sure if working)
  ({ 
      fd -H '^\.DS_Store$' -tf -X rm; 
      db put rm_ds_store "$(gdate '+%Y-%m-%dT%H:%M')";
    } &
  ) >|/dev/null 2>&1
}
## ---------------------------------------------
# update path in db
# db put "path" "${PATH}"
# cd $(cat $HOME/.zsh_reload.txt) || cd $HOME
cd "$(db get reload_dir)" || cd $HOME
## ---------------------------------------------
# uses the `debug` function, see utils.zsh
local CLEAR="$(db get clear)"
local DEBUG="$(db get debug)"
# do not clear output if debug is true, otherwise clear=clear
test $DEBUG == true || eval $CLEAR
## ---------------------------------------------
# LOAD COMPLETIONS LAST
autoload compinit
autoload bashcompinit
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
## ---------------------------------------------
