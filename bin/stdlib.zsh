# shellcheck shell=bash
# This file will mostly be used interactively, however it can
# work as a standalone library when sourced from other zsh scripts.
#
# `stdlib.zsh` can also be used with Lua / Teal to write shell scripts
#  by generating standalone files in the /src/bin directory for
#  use as a lua/zsh shared library
#    - See generate_binfiles() at the bottom of this file
#    - See zconf/src
#
# check if a file has access to stdlib.zsh by using `environ "stdlib"`
# at the top of the file. the command will fail at environ and when 
# checking for stdlib, if environ is somehow set and available. 
# shellcheck source=/Users/unforswearing/zsh-config/bin/stdlib.zsh
export stdlib="/Users/unforswearing/zsh-config/bin/stdlib.zsh"
# ###############################################
function libutil:reload() { source "${stdlib}"; }
function libutil:argtest() {
  # usage libutil:argtest num
  # libutil:argtest 2 => if $1 or $2 is not present, print message
  setopt errreturn
  # shellcheck disable=2154
  local caller=${funcstack[2]}
  if [[ -z "$1" ]]; then
    color red "$caller: argument missing"
    return 1
  fi
}
function libutil:error.option() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  color red "$caller: no method named '$fopt'" && return 1
}
function libutil:error.notfound() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  color red "$caller: $1 not found" && return 1
}
# ###############################################
# stdlib.zsh functions are available in imported files
function import() {
  declare ZSH_USR_DIR="/Users/unforswearing/zsh-config/usr"
  libutil:argtest "$1"
  declare -A imports
  case "$1" in
  "object") source "${ZSH_USR_DIR}/object.zsh" && imports["$1"]=true ;;
  "color") source "${ZSH_USR_DIR}/color.zsh" && imports["$1"]=true ;;
  "datetime") source "${ZSH_USR_DIR}/datetime.bash" && imports["$1"]=true ;;
  "dir") source "${ZSH_USR_DIR}/dir.zsh" && imports["$1"]=true ;;
  "file") source "${ZSH_USR_DIR}/file.zsh" && imports["$1"]=true ;;
  "net") source "${ZSH_USR_DIR}/net.zsh" && imports["$1"]=true ;;
  "async") source "${ZSH_USR_DIR}/async.zsh" && imports["$1"]=true ;;
  "await") source "${ZSH_USR_DIR}/await.zsh" && imports["$1"]=true ;;
  "extract") source "${ZSH_USR_DIR}/extract.bash" && imports["$1"]=true ;;
  "conv") source "${ZSH_USR_DIR}/conversion.zsh" && imports["$1"]=true ;;
  "update") source "${ZSH_USR_DIR}/update.zsh" && imports["$1"]=true ;;
  "help") source "${ZSH_USR_DIR}/help.zsh" && imports["$1"]=true ;;
  "cleanup") source "${ZSH_USR_DIR}/cleanup.zsh" && imports["$1"]=true ;;
  "lnks") source "${ZSH_USR_DIR}/lnks.bash" && imports["$1"]=true ;;
  "repl") source "${ZSH_USR_DIR}/replify.sh" && imports["$1"]=true ;;
  "jobs") source "${ZSH_USR_DIR}/jobs.zsh" && imports["$1"]=true ;;
  "gc") source "${ZSH_USR_DIR}/gc.zsh" && imports["$1"]=true ;;
  "iterm")
    test -e "${HOME}/.iterm2_shell_integration.zsh" &&
      source "${HOME}/.iterm2_shell_integration.zsh" && 
      imports["$1"]=true 
    ;;
  *) 
    libutil:error.option "$1"
    ;;
  esac
}
function getimports() {
  # 2296 disabled: using (k) is a valid method to get keys from assoc arrays
  # shellcheck disable=2296
  for item in ${(k)imports}; do print "$item -> ${imports[$item]}"; done
}
function isimported() {
  libutil:argtest "$1"
  local val=${imports["$1"]}
  if [[ -z "$val" ]]; then false; else true; fi
}
function unload() {
  libutil:argtest "$1"
  # "imports[$1]"
  ${imports["$1"]::=}
  unhash -f "$1" || libutil:error.option "$1"
}
# ###############################################
# require: ensure a command or builtin is available in the environment
# usage: require "gsed"
function require() {
  local comm
  comm="$(command -v "$1")"
  if [[ $comm ]]; then
    true
  else
    color red "$0: command '$1' not found" && return 1
  fi
}
function environ() {
  local varname
  varname="$1"
  if [[ -v "$varname" ]] && [[ -n "$varname" ]]; then
    true
  else 
    color red "$0: variable '$1' is not set or is not in environment" && return 1
  fi
}
# ###############################################
# topt: toggle the option - if on, turn off. if off, turn on
function topt() {
  libutil:argtest "$1"
  # shellcheck disable=2154,2203
  if [[ ${options[$1]} == "on" ]]; then
    unsetopt "$1"
  else
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]]; then checkopt "$1"; fi
}
function checkopt() {
  libutil:argtest "$1"
  # https://unix.stackexchange.com/a/121892
  print "${options[$1]}"
}
# function option() {
#   libutil:argtest "$1"
#   if [[ "$(checkopt "$1")" == "off" ]]; then
#     setopt "$1"
#   else 
#     true
#   fi
# }
# ###############################################
# ###############################################
# begin stdlib.zsh interactive functions
# -----------------------------------------------
import color
require "nu"
require "sd"
environ "options"
environ "functions"
# test `isfn get`; and "
#   print yes
# "; or "
#   print no
# ";
function and() {
  libutil:argtest "$@"
  # shellcheck disable=2181
  (($? == 0)) && eval "$@"
}
function or() {
  libutil:argtest "$@"
  # shellcheck disable=2181
  (($? == 0)) || eval "$@"
}
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
    local OIFS="$IFS"
    IFS=$'\n\t'
    local comm;
    comm=$(history | tail -n 1 | awk '{first=$1; $1=""; print $0;}')
    echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"
    IFS="$OIFS"
  }
  # similar to cmd.devnull, but command is used as
  # an argument to the function.
  # usage: cmd discard "ls | wc -l"
  function cmd.discard() {
    eval "$@" >|/dev/null 2>&1
  }
  # similar to cmd.devnull, but command is used
  # in / at the end of a pipe, not as an argument.
  # usage: ls | wc -l | cmd devnull
  function cmd.devnull() {
    # for use with pipes
    true >|/dev/null # 2>&1
  }
  # cmd norcs "declare -f periodic"
  # the above will print nothing since periodic is set in zshrc
  # use cmd norcs to run command in an env with no zsh sourcefiles
  function cmd.norcs() { 
    env -i zsh --no-rcs -c "$@"; 
  }
  # run a command with options enabled
  # cmd withopt "warncreateglobal warnnestedvars" "<cmd>"
  function cmd.withopt() {
    local opt="$1"
    shift
    setopt "$opt"
    eval "$@"
  }
  function cmd.noopt() {
    local opt="$1"
    shift
    unsetopt "$opt"
    eval "$@"
  }
  function cmd.settimeout() {
    local opt="$1"
    shift
    (sleep "$opt" && eval "$@") &
  }
  local opt="$1"
  shift
  case "$opt" in
  last) cmd.cpl ;;
  discard) libutil:argtest "$@" && cmd.discard "$@" ;;
  devnull) cmd.devnull ;;
  norcs) cmd.norcs "$@" ;;
  withopt) cmd.withopt "$@" ;;
  noopt) cmd.noopt "$@" ;;
  timeout) cmd.settimeout "$@" ;;
  *) libutil:error.option "$opt" ;;
  esac
}
# -------------------------------------------------
function puts() { print "$@"; }
function putf() {
  libutil:argtest "$@"
  printf "%s" "$@"
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
  local value=
  value="$(cat /dev/null)"
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
  local value="$*"
  # shellcheck disable=2145
  declare -rg "$name=$@"
  # shellcheck disable=2124
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
  declare -rg "$nameval=$nameval" >|/dev/null 2>&1
  # shellcheck disable=2034
  functions["$nameval"]="$nameval" >|/dev/null 2>&1
  atoms["$nameval"]="$nameval" >|/dev/null 2>&1
  stdtypes["$name"]="atom"
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
    print "$opt" | sd "^\s+" ""
  }
  trim.right() {
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
  # shellcheck disable=2124
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
  "select" \
  "coproc" \
  "nocorrect" \
  "repeat" \
  "float"
  # "until" \
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
  local functionbody
  functionbody=$(declare -f "$functionname")

  local binfile="${bindir}/${functionname}"
  # shellcheck disable=2140
  local argitems=("\\"" "$" "@" "\\"")

  puts "#!/opt/local/bin/zsh" >"$binfile"

  {
    puts "source \"${stdlib}\""
    puts "$functionbody"
    # shellcheck disable=2128
    puts "$functionname \"$(puts "$argitems" | sd " " "")\""
  } >>"$binfile"

  chmod +x "$binfile"
  setopt no_append_create
  setopt no_clobber
}
generate_binfile "generate_binfile"
generate_binfile "delete_binfiles"
