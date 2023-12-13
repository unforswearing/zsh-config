source "/Users/unforswearing/zsh-config/usr/color.zsh"
ZSH_USR_DIR="$ZSH_CONFIG_DIR/usr"

function req() {
  case "$1" in
  "alphanum") source "${ZSH_USR_DIR}/alphanum.zsh" ;;
  "color") source "${ZSH_USR_DIR}/color.zsh" ;;
  "async") eval "function async() { 
      ({ eval \"$@\"; } &) >/dev/null 2>&1 
    }" 
  ;;
  "extract") source "${ZSH_USR_DIR}/extract.bash" ;;
  "conv") source "${ZSH_USR_DIR}/conversion.zsh" ;;
  "help") source "${ZSH_USR_DIR}/help.zsh" ;;
  "repl") source "${ZSH_USR_DIR}/replify.sh" ;;
  "gc") source "${ZSH_USR_DIR}/garbage_collector.zsh" ;;
  *) 
    local comm="$(command -v $1)"
    if [[ $comm ]]; then
      true
    else
      color red "$0: command '$1' not found" && return 1
    fi
    ;;
  esac
}