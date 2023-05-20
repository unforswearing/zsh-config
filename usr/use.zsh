# run a command in another language
function use() {
  local opt="$1"
  shift
  case "$opt" in
  "py") python -c "$@" ;;
  # "lua") lua -e "$@" ;;
  "js") node -e "$@" ;;
  esac
}
