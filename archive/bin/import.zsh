  declare -A imports
  function import() {
    case "$1" in
    "object") source "${ZSH_USR_DIR}/object.zsh" && imports["$1"]=true ;;
    "color") source "${ZSH_USR_DIR}/color.zsh" && imports["$1"]=true ;;
    "datetime") source "${ZSH_USR_DIR}/datetime.bash" && imports["$1"]=true ;;
    "dirfile") source "${ZSH_USR_DIR}/dirfile.zsh" && imports["$1"]=true ;;
    "net") source "${ZSH_USR_DIR}/net.zsh" && imports["$1"]=true ;;
    "async") source "${ZSH_USR_DIR}/async.zsh" ;;
    "use") source "${ZSH_USR_DIR}/use.zsh" && imports["$1"]=true ;;
    "extract") source "${ZSH_USR_DIR}/extract.bash" && imports["$1"]=true ;;
    "conv") source "${ZSH_USR_DIR}/conversion.zsh" && imports["$1"]=true ;;
    "update") source "${ZSH_USR_DIR}/update.zsh" && imports["$1"]=true ;;
    "help") source "${ZSH_USR_DIR}/help.zsh" && imports["$1"]=true ;;
    "cleanup") source "${ZSH_USR_DIR}/cleanup.zsh" && imports["$1"]=true ;;
    "lnks") source "${ZSH_USR_DIR}/lnks.bash" && imports["$1"]=true ;;
    "repl") source "${ZSH_USR_DIR}/replify.sh" && imports["$1"]=true ;;
    "jobs") source "${ZSH_USR_DIR}/jobs.zsh" && imports["$1"]=true ;;
    "gc") source "${ZSH_USR_DIR}/garbage_collector.zsh" && imports["$1"]=true ;;
    "iterm")
      test -e "${HOME}/.iterm2_shell_integration.zsh" &&
        source "${HOME}/.iterm2_shell_integration.zsh" && 
        imports["$1"]=true 
      ;;
    *) 
      import color
      color red "no item to import: '$1'" 
      ;;
    esac
  }
  # to remove imported functions from the environment
  # unload "conv"
  function unload() {
    ${imports["$1"]::=}
    unhash -f "$1"
  }