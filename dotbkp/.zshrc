# ##################################################################
# Zsh Configuration Outline
# `$HOME/.zprofile`:
#   - $ZDOTDIR is set to $HOME/zsh-config
# `~zconf/.zshenv`:
#   - edit $PATH in `~zconf/.zshenv`
# `~zconf/bin/config.zsh`:
#   - exports, aliases, zsh config, setopt options, and source files
# `~zconf/bin/stdlib.zsh`:
#   - a standalone library for basic zsh interactive sessions
# `~zconf/usr`:
#   - standalone files used with the `req` function in `/bin`
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
# export ALIAS=($(alias))
export ZSH_CONFIG_DIR="$HOME/zsh-config"
export ZSH_BIN_DIR="$ZSH_CONFIG_DIR/bin"
## ---------------------------------------------
rabs() { "/usr/local/bin/abs" "$ZSH_BIN_DIR/abs/rabs.abs" "${@}"; }
source "${ZSH_CONFIG_DIR}/config.zsh"
source "${ZSH_CONFIG_DIR}/req.zsh"

req help
## ---------------------------------------------
function prev() {
  cd "${PREV}" || cd < "${HOME}/.zsh_reload.txt"
}
function reload() {
  source "${ZSH_CONFIG_DIR}/.zshrc" || exec zsh
}
function async() { (
  { eval "$@"; } &) >/dev/null 2>&1
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
  fd --base-directory ~/zsh-config/bin ${fd_options[@]} |
    # source all recently updated files
    while read item; do print "sourcing ${item}"; source "${item}"; done
  # source usr files
  fd --base-directory ~/zsh-config/usr ${fd_options[@]} |
    # source all recently updated files
    while read item; do print "sourcing ${item}"; source "${item}"; done

  source "/Users/unforswearing/zsh-config/.zshrc"
  setopt warn_create_global
}
function cpl() {
  req "pee"
  OIFS="$IFS"
  IFS=$'\n\t'
  local comm=$(history | tail -n 1 | awk '{first=$1; $1=""; print $0;}')
  echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"
  IFS="$OIFS"
}
function opts() {
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
## the folling are not used:
# - command_not_found_handler() {;}
# - preexec() {;}
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
  ({
    find . -name '*.DS_Store' -type f -ls -delete
  }&) >|/dev/null 2>&1
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
# LOAD COMPLETIONS LAST
autoload compinit
autoload bashcompinit
# brew install zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
eval "$(direnv hook zsh)"
## ---------------------------------------------
setopt warn_create_global
## ---------------------------------------------
