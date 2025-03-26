# shellcheck shell=bash
environ "stdlib"
## ---------------------------------------------
function lower() {
  libutil:argtest "$1"
  local opt="${1}"
  print "$opt" | tr '[:upper:]' '[:lower:]'
}
function upper() {
  libutil:argtest "$1"
  local opt="${1}"
  print "$opt" | tr '[:lower:]' '[:upper:]'
}
function trim() {
  function trim.left() {
    local opt="${1:-$(cat -)}"
    libutil:argtest "$opt"
    print "$opt" | sd "^\s+" ""
  }
  function trim.right() {
    local opt="${1:-$(cat -)}"
    libutil:argtest "$opt"
    print "$opt" | sd "\s+$" ""
  }
  libutil:argtest "$2"
  case "$1" in
  left) trim.left "$2" ;;
  right) trim.right "$2" ;;
  esac
}
function contains() {
  # using nushell
  libutil:argtest "$1"
  local result
  result=$(nu -c "echo $(cat -) | str contains $1")
  if [[ $result == "true" ]]; then true; else false; fi
}
# a string matcher, since the `eq` function only works for numbers
# match will check the entire string. use contains for string parts
function match() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  local left="${1}"
  local right="${2}"
  if [[ "$left" == "$right" ]]; then true; else false; fi
}
# a simple replace command
function replace() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  sd "${1}" "${2}"
}
function count() {
  # do not use libutil:argtest for math / counting functions
  local char=" "
  function count.lines() {
    local opt="${1:-$(cat -)}"
    print "$opt" | wc -l | sd "^\s+" ""
  }
  function count.words() {
    local opt="${1:-$(cat -)}"
    print "$opt" | wc -w | sd "^\s+" ""
  }
  function count.chars() {
    local opt="${1:-$(cat -)}"
    print "${#opt}"
  }
  local opt="$1"
  shift
  case "$opt" in
  lines) count.lines "$@" ;;
  words) count.words "$@" ;;
  chars) count.chars "$@" ;;
  *) libutil:error.option "$opt" ;;
  esac
}