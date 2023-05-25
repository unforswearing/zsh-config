# shellcheck shell=bash
# pseudo types were pulled from stdlib. 
# @todo revise how these work (numbers should be numbers, etc)
#       -> use a different programming language if needed
# @todo develop an internal way to track references to the types
# @todo once internal type method is derived, create funcs to get and convert types
# 
# create pseudo types: nil, num, const, atom
function nil() {
  libutil:argtest "$1"
  # a nil type
  # use `cmd discard` for sending commands to nothingness
  local name="$1"
  local value=
  value="$(cat /dev/null)"
  declare -rg "$name=$value"
  # nils["$name"]=true
  # stdtypes["$name"]="nil"
  eval "function $name() print $value;"
}
function num() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  local name="$1"
  local value="$2"
  declare -rg "$name=$value"
  # nums["$name"]="$((value))"
  # stdtypes["$name"]="num"
  eval "function $name() print $value;"
}
# const utencil "spoon"
function const() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  local name="$1"
  shift
  local value="$*"
  # shellcheck disable=2145
  declare -rg "$name=$@"
  # shellcheck disable=2124
  # consts["$name"]="$@"
  # stdtypes["$name"]="const"
  eval "function $name() print $value"
}
# atom, single item of data. a number or word
# the concept of atoms are taken from elixir
#   - a constant whose value is its name
# eg atom hello => hello=hello
# useage: atom value
function atom() {
  libutil:argtest "$1"
  local nameval="$1"
  eval "function $nameval() print $nameval;"
  # if $1 is a number, don't use declare
  declare -rg "$nameval=$nameval" >|/dev/null 2>&1
  # shellcheck disable=2034
  functions["$nameval"]="$nameval" >|/dev/null 2>&1
  # atoms["$nameval"]="$nameval" >|/dev/null 2>&1
  # stdtypes["$name"]="atom"
}
# -------------------------------------------------
# check the type of various vars
function typeof() {
  libutil:argtest "$1"
  local val=${stdtypes["$1"]}
  if [[ -z $val ]]; then print "none"; else print "$val"; fi
}
function isnil() {
  # nil has no value so there is no `get nil` command
  libutil:argtest "$1"
  local testval=${nils["$1"]}
  if [[ "$testval" != true ]]; then false; else true; fi
}
function isnum() {
  libutil:argtest "$1"
  local testval
  testval="$(get num "$1")"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isconst() {
  libutil:argtest "$1"
  local testval
  testval="$(get const "$1")"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isatom() {
  libutil:argtest "$1"
  local testval
  testval="$(get atom "$1")"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isfn() {
  libutil:argtest "$1"
  local char=" "
  local result
  result=$(
    type -w "$1" | awk -F: '{print $2}' | sed "s%^[${char//%/\\%}]*%%"
  )
  if [[ -z "$result" ]]; then
    false
  elif [[ $result == "function" ]]; then
    true
  else
    false
  fi
}
function get() {
  libutil:argtest "$1"
  function getnum() {
    local val=${nums["$1"]}
    if [[ -z $val ]]; then false; else print "$val"; fi
  }
  function getconst() {
    local val=${consts["$1"]}
    if [[ -z $val ]]; then false; else print "$val"; fi
  }
  function getatom() {
    local val=${atoms["$1"]}
    if [[ -z $val ]]; then false; else print "$val"; fi
  }
  function getvar() {
    # dont use $ with var
    # getvar PATH
    # todo: hide output if there is no match
    local value
    value=$(eval "print \$${1}")
    if [[ -z "$value" ]]; then
      libutil:error.notfound "$1"
    else
      print "$value"
    fi
  }
  function getfn() {
    # todo: hide output if there is no match
    declare -f "$1"
  }
  local opt="$1"
  shift
  case "$opt" in
  num) libutil:argtest "$1" && getnum "$1" ;;
  const) libutil:argtest "$1" && getconst "$1" ;;
  atom) libutil:argtest "$1" && getatom "$1" ;;
  var) libutil:argtest "$1" && getvar "$1" ;;
  fn) libutil:argtest "$1" && getfn "$1" ;;
  *) libutil:argtest "$1" && libutil:error.option "$opt" ;;
  esac
}