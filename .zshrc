# ##################################################################
# Zsh Configuration Outline
# `$HOME/.zprofile`:
#   - $ZDOTDIR is set to $HOME/zsh-config
# `~zconf/.zshrc` and `~zconf/.zshenv`:
#   - copied to $HOME from `~zconf/bin/config.zsh`
#   - edit $PATH in `~zconf/.zshenv`
# `~zconf/bin/config.zsh`:
#   - exports, aliases, zsh config, setopt options, and source files
#   - `config.zsh` uses files from `/plugin`, `/sql`, `/theme`
# `~zconf/bin/stdlib.zsh`:
#   - a standalone library for basic zsh interactive sessions
#   - this file can also be used with lua shell scripts
# `~zconf/src`:
#   - structure for using lua to create shell scripts with stdlib.zsh as a library
# `~zconf/usr`:
#   - standalone files used with the `import` function in `/bin`
# ##################################################################
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
function reload() { exec zsh; }
# source all files in the /usr directory
fd -t f --max-depth 1 . "$ZSH_BIN_DIR" | while read _config_file_; do
  local shortname="$(basename $_config_file_)"
  source "$_config_file_" || print "failed: $shortname"
done
# the  `import` function is in bin/config.zsh
import color
import help
import iterm
import lnks
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
      history |
        gtail -n 1 |
        awk '{first=$1; $1=""; print $0;}' |
        sed 's/\"//g'
    )"
    sqlite3 /Users/unforswearing/zsh_history.db \
      "insert into history (val) values (\"$prev\")"
    # >|/dev/null 2>&1
  })
}
periodic() {
  db put env_period "$PERIOD"
  # --------------------------------------
  # update hosts file from stevenblack/hosts
  (
    {
      python3 "${ZSH_USR_DIR}/hosts.py"
      db put hosts_file_updated "$(gdate '+%Y-%m-%dT%H:%M')"
    } &
  ) >|/dev/null 2>&1
  # --------------------------------------
  # remove all .DS_Store files (not sure if working)
  (
    {
      find . -name '*.DS_Store' -type f -ls -delete
      db put rm_ds_store "$(gdate '+%Y-%m-%dT%H:%M')"
    } &
  ) >|/dev/null 2>&1
  db put periodic_function "$(which periodic | base64)"
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
# brew install zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
eval "$(direnv hook zsh)"
## ---------------------------------------------
