# add all contents of this file to $ZSH_BIN_DIR/stdlib.zsh
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
ltrim() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print $opt | sd "^\s+" ""
}
rtrim() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print $opt | sd "\s+$" ""
}
function trim() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print "$opt" | sd "(^\s+|\s+$)" ""
}
function length() {
   libutil:argtest "$1"
   local arg="${1}"
   print "${#arg}"
}
function toiter() {
  # split a string by char into newlines for iterating over
   libutil:argtest "$1"
   local arg="${1}"
   print "$arg" | trim | sd "" "\n" | tail -n +2
}
function contains() {
  # using nushell
  libutil:argtest "$1"
  local str="${2:-$(cat -)}"
  local result=$(echo "$str" | grep -o "$1")
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
# math -------------------------------------------
# all math commands (AND ONLY MATH COMMANDS) can be used in two ways:
# add 2 2 => 4
# print 2 | add 2 => 4
function add() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left + right))"
}
function sub() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left - right))"
}
function mul() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left * right))"
}
function div() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left / right))"
}
function pow() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left ** right))"
}
function mod() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left % right))"
}
function eq() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -eq "$right" ]]; then true; else false; fi
}
function ne() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -ne "$right" ]]; then true; else false; fi
}
function gt() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -gt "$right" ]]; then true; else false; fi
}
function lt() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -lt "$right" ]]; then true; else false; fi
}
function ge() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -ge "$right" ]]; then true; else false; fi
}
function le() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -le "$right" ]]; then true; else false; fi
}
function incr() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print $((++opt))
}
function decr() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print $((--opt))
}
function sum() {
  local valueargs="${@:-$(cat -)}"
  libutil:argtest "$valueargs"
  print "${valueargs}" |
    awk '{for(i=1; i<=NF; i++) sum+=$i; } END {print sum}'
}