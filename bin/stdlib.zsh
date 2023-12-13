# This file will mostly be used interactively, however it can
# work as a standalone library when sourced from other zsh scripts.
#
# `stdlib.zsh` can also be used with Lua / Teal to write shell scripts
#  by generating standalone files in the /src/bin directory for
#  use as a lua/zsh shared library
#    - See generate_binfiles() at the bottom of this file
#    - See zconf/src
#

export stdlib="${ZSH_BIN_DIR}/stdlib.zsh"

req color

setopt bsd_echo
setopt c_precedences
setopt cshjunkie_loops
setopt function_argzero
setopt ksh_zero_subscript
setopt local_loops
setopt local_options
setopt no_append_create
setopt no_clobber
setopt sh_word_split
setopt warn_create_global

function libutil:reload() { source "${stdlib}"; }
function libutil:argtest() {
  # usage libutil:argtest num
  # libutil:argtest 2 => if $1 or $2 is not present, print message
  setopt errreturn
  local caller=$funcstack[2]
  if [[ -z "$1" ]]; then
    color red "$caller: argument missing"
    return 1
  fi
}
function libutil:error.option() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=$funcstack[2]
  local fopt="$1"
  color red "$caller: no method named '$fopt'" && return 1
}
function libutil:error.notfound() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=$funcstack[2]
  local fopt="$1"
  color red "$caller: $1 not found" && return 1
}
# ###############################################
function sysinfo() {
  libutil:argtest "$1"
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
function cmd() {
  libutil:argtest "$1"
  function cmd.cpl() {
    req "pee"
    OIFS="$IFS"
    IFS=$'\n\t'
    local comm=$(history | tail -n 1 | awk '{first=$1; $1=""; print $0;}')
    echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"
    IFS="$OIFS"
  }
  function cmd.discard() {
    eval "$@" >|/dev/null 2>&1
  }
  local opt="$1"
  shift
  case "$opt" in
  last) cmd.cpl ;;
  discard) libutil:argtest "$@" && cmd.discard "$@" ;;
  *) libutil:error.option "$opt" ;;
  esac
}
# -------------------------------------------------
function puts() { print "$@"; }
function putf() {
  libutil:argtest "$1"
  local str="$1"
  shift
  libutil:argtest "$@"
  printf "$str" "$@"
}
# -------------------------------------------------
# create pseudo types: nil, num, const, atom
declare -A stdtypes
declare -A nils
function nil() {
  libutil:argtest "$1"
  # a nil type
  # use `cmd discard` for sending commands to nothingness
  local name="$1"
  local value="$(cat /dev/null)"
  declare -rg "$name=$value"
  nils["$name"]=true
  stdtypes["$name"]="nil"
  eval "function $name() print $value;"
}
declare -A nums
function num() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  local name="$1"
  local value="$2"
  declare -rg "$name=$value"
  nums["$name"]="$((value))"
  stdtypes["$name"]="num"
  eval "function $name() print $value;"
}
# const utencil "spoon"
declare -A consts
function const() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  local name="$1"
  shift
  local value="$@"
  declare -rg "$name=$@"
  consts["$name"]="$@"
  stdtypes["$name"]="const"
  eval "function $name() print $value"
}
# atom, single item of data. a number or word
# the concept of atoms are taken from elixir
#   - a constant whose value is its name
# eg atom hello => hello=hello
# useage: atom value
declare -A atoms
function atom() {
  libutil:argtest "$1"
  local nameval="$1"
  eval "function $nameval() print $nameval;"
  # if $1 is a number, don't use declare
  declare -rg $nameval="$nameval" >|/dev/null 2>&1
  functions["$nameval"]="$nameval" >|/dev/null 2>&1
  atoms["$nameval"]="$nameval" >|/dev/null 2>&1
  stdtypes["$name"]="atom"
}
# -------------------------------------------------
# check the type of various vars
function typeof() {
  libutil:argtest "$1"
  local val=$stdtypes["$1"]
  if [[ -z $val ]]; then print "none"; else print "$val"; fi
}
function isnil() {
  # nil has no value so there is no `get nil` command
  libutil:argtest "$1"
  local testval=$nils["$1"]
  if [[ "$testval" != true ]]; then false; else true; fi
}
function isnum() {
  libutil:argtest "$1"
  local testval="$(get num $1)"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isconst() {
  libutil:argtest "$1"
  local testval="$(get const $1)"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isatom() {
  libutil:argtest "$1"
  local testval="$(get atom $1)"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isfn() {
  libutil:argtest "$1"
  local char=" "
  local result=$(
    type -w "$1" | awk -F: '{print $2}' | sed "s%^[${char//%/\\%}]*%%"
  )
  if [[ -z "$result" ]]; then
    false
  elif [[ $result == "function" ]]; then true; else false; fi
}
function get() {
  libutil:argtest "$1"
  function getnum() {
    local val=$nums["$1"]
    if [[ -z $val ]]; then false; else print "$val"; fi
  }
  function getconst() {
    local val=$consts["$1"]
    if [[ -z $val ]]; then false; else print "$val"; fi
  }
  function getatom() {
    local val=$atoms["$1"]
    if [[ -z $val ]]; then false; else print "$val"; fi
  }
  function getvar() {
    # dont use $ with var
    # getvar PATH
    # todo: hide output if there is no match
    local value=$(eval "print \$"${1}"")
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
  #libutil:argtest "$2"
  shift
  case "$opt" in
  num) getnum "$2" ;;
  const) getconst "$2" ;;
  atom) getatom "$2" ;;
  var) getvar "$2" ;;
  fn) getfn "$2" ;;
  *) libutil:error.option "$opt" ;;
  esac
}
## ---------------------------------------------
function calc() {
  libutil:argtest "$1"
  print "$@" | bc
}
## ---------------------------------------------
# disable the use of some keywords by creating empty aliases
disable -r "integer" \
  "time" \
  "until" \
  "select" \
  "coproc" \
  "nocorrect" \
  "repeat" \
  "float";
