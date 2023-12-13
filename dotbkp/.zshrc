# ##################################################################
# Zsh Configuration Outline
# `$HOME/.zprofile`:
#   - $ZDOTDIR is set to $HOME/zsh-config
# `~zconf/.zshenv`:
#   - edit $PATH in `~zconf/.zshenv`
# `~zconf/bin/config.zsh`:
#   - exports, aliases, zsh config, setopt options, and source files
#   - `config.zsh` uses files from `/plugin`, `/sql`, `/theme`
# `~zconf/bin/stdlib.zsh`:
#   - a standalone library for basic zsh interactive sessions
#   - this file can also be used with lua shell scripts
# `~zconf/usr`:
#   - standalone files used with the `import` function in `/bin`
# #################################################################
unsetopt warn_create_global
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
export ZSH_BIN_DIR="$ZSH_CONFIG_DIR/bin"
export ZSH_USR_DIR="$ZSH_CONFIG_DIR/usr"
## ---------------------------------------------
{
  source "${ZSH_BIN_DIR}/config.zsh";
  source "${ZSH_BIN_DIR}/req.zsh";
  source "${ZSH_BIN_DIR}/stdlib.zsh";
} &
## ---------------------------------------------
function reload() { source "${ZSH_CONFIG_DIR}/.zshrc" || exec zsh; }
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
## ---------------------------------------------
# BOTTOM: hooks / builtin event handlers
## the folling are not used:
# - command_not_found_handler() {;}
# - preexec() {;}
precmd() {
  # save the current dir to auto-cd if iterm crashes
  pwd >|"$HOME/.zsh_reload.txt" &
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
  # db put env_period "$PERIOD"
  # --------------------------------------
  # update hosts file from stevenblack/hosts
  ({ python3 "${ZSH_USR_DIR}/hosts.py"; } &) >|/dev/null 2>&1
  # --------------------------------------
  # remove all .DS_Store files (not sure if working)
  (
    {
      find . -name '*.DS_Store' -type f -ls -delete
    } &
  ) >|/dev/null 2>&1
}
## ---------------------------------------------
# cd $(cat $HOME/.zsh_reload.txt) || cd $HOME
cd "$PREV" || cd "$HOME"
## ---------------------------------------------
# uses the `debug` function, see utils.zsh
# do not clear output if debug is true, otherwise clear=clear
test $DEBUG || eval $CLEAR
## ---------------------------------------------
# backup .zshrc and .zshenv
{ \cp "${ZSH_CONFIG_DIR}/.zshrc" "${HOME}/zsh-config/dotbkp"; } &
{ \cp "${ZSH_CONFIG_DIR}/hosts.py" "${HOME}/zsh-config/dotbkp"; } &
{ \cp "${HOME}/.zshenv" "${HOME}/zsh-config/dotbkp"; } &
# source zsh-config/.zshrc from $HOME/.zshrc
{ echo "source $0" >| "${HOME}/.zshrc"; }
## ---------------------------------------------
# LOAD COMPLETIONS LAST
autoload compinit
autoload bashcompinit
# brew install zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
eval "$(direnv hook zsh)"
## ---------------------------------------------
setopt warn_create_global
## ---------------------------------------------
