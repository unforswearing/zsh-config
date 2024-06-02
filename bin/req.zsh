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

  # merge alphanum and color into $ZSH_BIN_DIR/stdlib.zsh
  # keep help and repl here as modules
  case "$1" in
  "help") source "${ZSH_USR_DIR}/help.zsh" && success ;;
  "repl") source "${ZSH_USR_DIR}/replify.sh" && success ;;
  "stdlib") source $ZSH_BIN_DIR/stdlib.zsh && success ;;
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
