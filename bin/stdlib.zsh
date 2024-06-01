# This file will mostly be used interactively, however it can
# work as a standalone library when sourced from other zsh scripts.
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
# do something if the previous command succeeds
function and() { (($? == 0)) && "$@"; }
# do something if the previous command fails
function or() { (($? == 0)) || "$@"; }
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
declare -a stdtypes=()
declare -a nils
function nil() {
  libutil:argtest "$1" || return 
  # a nil type
  # use `cmd discard` for sending commands to nothingness
  local name="$1"
  local value="$(cat /dev/null)"
  nils+=("$name=$(true)")
  stdtypes+=("$name=nil")
  eval "function $name() print $value;"
  declare -rg "$name=$value"
}
declare -a nums
function num() {
  { 
    libutil:argtest "$1" &&
    libutil:argtest "$2" 
  } || return
  local name="$1"
  local value="$2"
  nums+=("$name=$((value))")
  stdtypes+=("$name=num")
  eval "function $name() print $value;"
  declare -rg "$name=$value"
}
# const utencil "spoon"
declare -a consts
function const() {
  { 
    libutil:argtest "$1" &&
    libutil:argtest "$2" 
  } || return
  local name="$1"
  shift
  local value="$@"
  consts+=("$name=$@")
  stdtypes+=("$name=const")
  eval "function $name() print $value"
  declare -rg "$name=$@"
}
# atom, single item of data. a number or word
# the concept of atoms are taken from elixir
#   - a constant whose value is its name
# eg atom hello => hello=hello
# useage: atom value
declare -a atoms
function atom() {
  libutil:argtest "$1" || return
  local nameval="$1"
  eval "function $nameval() print $nameval;"
  # if $1 is a number, don't use declare
  declare -rg $nameval="$nameval" >|/dev/null 2>&1
  functions["$nameval"]="$nameval" >|/dev/null 2>&1
  atoms+=("$nameval") >|/dev/null 2>&1
  stdtypes+=("$nameval=atom")
}
# -------------------------------------------------
# check the type of various vars
function typeof() {
  libutil:argtest "$1"
  for val in ${stdtypes[@]}; do
    test $(<<<"${val}" | grep -o $1) && \
      print "${val}" | sd "^.*=" "" || \
      print "none"
    # if [[ $1 =~ $val ]]; then print "$val"; else print "none"; fi
  done
}
function isnum() {
  unsetopt warncreateglobal
  libutil:argtest "$1"
  local testval="$1"
  # deprecated: if [[ -z "$testval" ]]; then false; else true; fi
  # check if a value is a number (including floating point numbers and negatives)
  [[ "$testval" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]
}
function isstr() {
  unsetopt warncreateglobal
  libutil:argtest "$1"
  local testval="$1"  
  [[ "$testval" =~ [^0-9] ]]
}
function isarray() {
  unsetopt warncreateglobal
  libutil:argtest "$1"
  local testval="$1"
  # [[ "$(declare -p $testval)" =~ "declare -a" ]]
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
