source "/Users/unforswearing/zsh-config/usr/color.zsh"
ZSH_USR_DIR="$ZSH_CONFIG_DIR/usr"

function req() {
  unsetopt warn_create_global && \
    caller="$0" && arg="$1" && \
    setopt warn_create_global

  function success() { color green "$caller: '$arg' loaded"; }

  if [[ "$1" == ":mute" ]] && {
    function success() { :; }
    shift
  }

  case "$1" in
  "alphanum") source "${ZSH_USR_DIR}/alphanum.zsh" && success ;;
  "color") source "${ZSH_USR_DIR}/color.zsh"  && success ;;
  "help") source "${ZSH_USR_DIR}/help.zsh" && success ;;
  "repl") source "${ZSH_USR_DIR}/replify.sh" && success ;;
  ""|" "*) color red "$0: please enter a command" && success ;;
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
