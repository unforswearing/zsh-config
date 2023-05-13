# For interactive use.
# Use Lua / Teal to write shell scripts. See zconf/src.
## Uncommon Zsh Syntax to use
# - in some cases it is easier to just use the uncommon versions of zsh syntax
### examples:
# - short versions of commands
#   - these can be changed using various options via 'setopt'
#   - https://unix.stackexchange.com/a/468597
# - anonymous functions
#   () {
#     local thisvar="inside function"
#     print "this will show $thisvar immediately"
#   }

source "${ZSH_BIN_DIR}/import.zsh"
source "${ZSH_BIN_DIR}/require.zsh"

import color
require "nu"
require "sd"

setopt bsd_echo
setopt c_precedences
setopt cshjunkie_history
setopt cshjunkie_loops
setopt function_argzero
setopt ksh_zero_subscript
setopt local_loops
setopt local_options
setopt no_append_create
setopt no_clobber
setopt sh_word_split
setopt warn_create_global

export stdlib="${ZSH_BIN_DIR}/stdlib.zsh"
function libreload() { source "${stdlib}"; }
function reload() { exec zsh; }
# usage libutil:argtest num
# libutil:argtest 2 => if $1 or $2 is not present, print message
function libutil:argtest() {
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
    require "pee"
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
# topt: toggle the option - if on, turn off. if off, turn on
function topt() {
  libutil:argtest "$1"
  if [[ $options[$1] == "on" ]]; then
    unsetopt "$1"
  else
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]]; then checkopt $1; fi
}
function checkopt() {
  # https://unix.stackexchange.com/a/121892
  print $options[$1]
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
  local result=$(type -w "$1" | awk -F: '{print $2}' | sed "s%^[${char//%/\\%}]*%%")
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
  trim.left() {
    local opt="${1:-$(cat -)}"
    libutil:argtest "$opt"
    print $opt | sd "^\s+" ""
  }
  trim.right() {
    local opt="${1:-$(cat -)}"
    libutil:argtest "$opt"
    print $opt | sd "\s+$" ""
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
  local result=$(nu -c "echo $(cat -) | str contains $1")
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
  "float"

## ---------------------------------------------
# create a standalone, top-level file for *almost* any zsh function
# -> functions that use the ${1:-$(cat -)} construction wont work
#
# for use with lua scripts via "luash". for example:
#
# ```lua
# require("luash")
# generate_binfile("incr")
# print(incr(5))
# ```
# generated files are added to "/Users/unforswearing/zsh-config/src/bin"
#
function delete_binfiles() {
  /bin/rm -r /Users/unforswearing/zsh-config/src/bin/*
  generate_binfile "generate_binfile"
  generate_binfile "delete_binfiles"
}
function generate_binfile() {
  unsetopt no_append_create
  unsetopt no_clobber
  local bindir="/Users/unforswearing/zsh-config/src/bin"
  path+="$bindir"

  local functionname="${1}"
  local functionbody=$(get fn $functionname)

  local binfile="${bindir}/${functionname}"
  local argitems=("\\"" "$" "@" "\\"")

  puts "#!/opt/local/bin/zsh" >|"$binfile"

  {
    puts "source \"${stdlib}\""
    puts "$functionbody"
    puts "$functionname \"$(puts $argitems | sd " " "")\""
  } >>"$binfile"

  chmod +x "$binfile"
  setopt no_append_create
  setopt no_clobber
}
generate_binfile "generate_binfile"
generate_binfile "delete_binfiles"
