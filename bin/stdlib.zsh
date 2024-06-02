# This file will mostly be used interactively, however it can
# work as a standalone library when sourced from other zsh scripts.
#

export stdlib="${ZSH_BIN_DIR}/stdlib.zsh"

source "${ZSH_BIN_DIR}/req.zsh"

req :mute print

function color() {
  local red="\033[31m"
  local green="\033[32m"
  local yellow="\033[33m"
  local blue="\033[34m"
  local reset="\033[39m"
  local black="\033[30m"
  local white="\033[37m"
  local magenta="\033[35m"
  local cyan="\033[36m"
  local opt="$1"
  shift
  case "$opt" in
    red) print "${red}$@${reset}" ;;
    green) print "${green}$@${reset}" ;;
    yellow) print "${yellow}$@${reset}" ;;
    blue) print "${blue}$@${reset}" ;;
    black) print "${black}$@${reset}" ;;
    white) print "${white}$@${reset}" ;;
    magenta) print "${magenta}$@${reset}" ;;
    cyan) print "${cyan}$@${reset}" ;;
    help) print "colors <red|green|yellow|blue|black|magenta|cyan> string" ;;
  esac
}

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

setopt errreturn

function libutil:reload() { source "${stdlib}"; }
function libutil:argtest() {
  # usage libutil:argtest num
  # libutil:argtest 2 => if $1 or $2 is not present, print message
  local caller=$funcstack[2]
  if [[ -z "$1" ]]; then
    color red "$caller: argument missing"
    return 1
  fi
}
function libutil:error.option() {
  libutil:argtest "$1"
  local caller=$funcstack[2]
  local fopt="$1"
  color red "$caller: no method named '$fopt'" && return 1
}
function libutil:error.notfound() {
  libutil:argtest "$1"
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
# run a command in another language
function use() {
  local opt="$1"
  shift
  case "$opt" in
  "py") python -c "$@" ;;
  "lua") lua -e "$@" ;;
  "js") node -e "$@" ;;
  esac
}
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
# function isarray() {
#   unsetopt warncreateglobal
#   libutil:argtest "$1"
#   local testval="$1"
#   # [[ "$(declare -p $testval)" =~ "declare -a" ]]
# }
## ---------------------------------------------
# alphanum
# Function to safely quote a string
safequote() {
  local input="$1"
  local quoted=""

  # Escape special characters
  quoted=$(printf '%q' "$input")

  # Return the safely quoted string
  echo "$quoted"
}
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
## ---------------------------------------------
# datetime: NOTE needs testing
datetime() {
  req st
  local opt="${1}"
  case "${opt}" in
  "day") gdate +%d ;;
  "month") gdate +%m ;;
  "year") gdate +%Y ;;
  "hour") gdate +%H ;;
  "minute") gdate +%M ;;
  "now") gdate --universal ;;
    # a la new gDate().getTime() in javascript
  "get_time") gdate -d "${2}" +"%s" ;;
  "add_days")
    local convtime
    convtime=$(st get_time "$(st now)")
    timestamp="$(st get_time ${2})"
    day=${3:-1}
    gdate -d "$(gdate -d "@${timestamp}" '+%F %T')+${day} day" +'%s'
    ;;
  "add_months")
    declare timestamp month
    local convtime
    local ts
    convtime=$(st get_time "$(st now)")
    ts=$(st get_time ${2})
    timestamp="${ts:$convtime}"
    month=${3:-1}
    gdate -d "$(gdate -d "@${timestamp}" '+%F %T')+${month} month" +'%s'
    ;;
  "add_weeks")
    declare timestamp week
    local convtime
    local ts
    convtime=$(st get_time "$(st now)")
    ts=$(st get_time ${2})
    timestamp="${ts:$convtime}"
    week=${3:-1}
    gdate -d "$(gdate -d "@${timestamp}" '+%F %T')+${week} week" +'%s'
    ;;
  esac
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
