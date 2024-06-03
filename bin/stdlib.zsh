# This file will mostly be used intectively, however it can
# work as a standalone library when sourced from other zsh scripts.
#

export stdlib="${ZSH_BIN_DIR}/stdlib.zsh"

{ command -v req >/dev/null 2>&1; } || \
  source "${ZSH_BIN_DIR}/req.zsh"

req :mute print

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
# ---------------
RE_ALPHA="[aA-zZ]"
RE_STRING="([aA-zZ]|[0-9])+"
RE_WORD="\w"
RE_NUMBER="\d"
RE_NUMERIC="^[0-9]+$"
RE_ALNUM="([aA-zZ]|[0-9])"
RE_NEWLINE="\n"
RE_SPACE=" "
RE_TAB="\t"
RE_WHITESPACE="\s"
POSIX_UPPER="[:upper:]"
POSIX_LOWER="[:lower:]"
POSIX_ALPHA="[:alpha:]"
POSIX_DIGIT="[:digit:]"
POSIX_ALNUM="[:alnum:]"
POSIX_PUNCT="[:punct:]"
POSIX_SPACE="[:space:]"
POSIX_WORD="[:word:]"

ERROR_LOG_FILE=
PRINT_STACK_TRACE=

# ---------------
timestamp() { "$(date +'%Y-%m-%d %H:%M:%S')"; }
log() {
  local message="$*"
  color green "$(timestamp) [LOG] $message"
}
# Function to handle errors with advanced features
error() {
  local exit_code=$1
  shift
  local message="$*"
  
  local timestamp="$(timestamp)"

  # Print the error message to stderr with a timestamp
  color red "$timestamp [ERROR] $message" >&2
  
  # Log the error message to a file (optional)
  if [[ -n "$ERROR_LOG_FILE" ]]; then
    color red "$timestamp [ERROR] $message" >> "$ERROR_LOG_FILE"
  fi
  
  # Print stack trace (optional)
  if [[ -n "$PRINT_STACK_TRACE" ]]; then
    echo "Stack trace:" >&2
    local i=0
    while caller $i; do
      ((i++))
    done >&2
  fi
  
  # Exit with the provided exit code (optional)
  if [[ "$exit_code" -ne 0 ]]; then
    exit "$exit_code"
  fi
}
# # Example usage
# ERROR_LOG_FILE="/path/to/error.log"  # Set this variable if you want to log errors to a file
# PRINT_STACK_TRACE=1  # Set this variable if you want to print stack traces

# # Example of logging an error with a stack trace
# error 0 "This is a test error message that doesn't exit the script"

# # Example of logging an error, printing a stack trace, and exiting the script
# error 1 "This is a critical error message that will exit the script"
# -----------------------------------------------
function async() { ({ eval "$@"; } &) >/dev/null 2>&1 }
function discard() { eval "$@" >|/dev/null 2>&1 }
# ###############################################
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
# ifcmd "cmd" && cmd last
# ifcmd "req" || source req
function ifcmd() {
  libutil:argtest "$1"
  test "$(command -v "${1}")"
}
# Function to retrieve user input with an optional message
function input() {
  local message="$1"
  
  # Print the message if provided
  if [[ -n "$message" ]]; then
    echo -n "$message "
  fi
  
  # Retrieve and return user input
  read user_input
  echo "$user_input"
}
function puts() { print "$@"; }
function putf() {
  libutil:argtest "$1"
  local str="$1"
  shift
  libutil:argtest "$@"
  printf "$str" "$@"
}
# -------------------------------------------------
# do something if the previous command succeeds
function and() { (($? == 0)) && "$@"; }
# do something if the previous command fails
function or() { (($? == 0)) || "$@"; }
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
strbuild() {
  # strbuild new "name"
  # name add "this is the next sentence."
  # name add $(safequote "here is some unsafe text: eval rm -rf. this string will not execute")
  # name print 
  # name compile
  case "$1" in
  new) printf "%s" "${2}" ;;
  esac
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
# filter a stream of text (multiple lines) using basic regex
# filter should be used in a pipe!
function filter() {
  local opt="${1}"
  local excl=
  [[ "$opt" == "exclude" ]] && {
    excl="!"
    opt="${2}"
  }
  case "${opt}" in
  "alpha") awk ${excl}/"${RE_ALPHA}"/ ;;
  "string") awk ${excl}/"${RE_STRING}"/ ;;
  "word") awk ${excl}/"${RE_WORD}"/ ;;
  "number") awk ${excl}/"${RE_NUMBER}"/ ;;
  "numeric") awk ${excl}/"${RE_NUMERIC}"/ ;;
  "alnum") awk ${excl}/"${RE_ALNUM}"/ ;;
  "newline") awk ${excl}/"${RE_NEWLINE}"/ ;;
  "space") awk ${excl}/"${RE_SPACE}"/ ;;
  "tab") awk ${excl}/"${RE_TAB}"/ ;;
  "whitespace") awk ${excl}/"${RE_WHITESPACE}"/ ;;
  "pupper") awk ${excl}/"${POSIX_UPPER}"/ ;;
  "plower") awk ${excl}/"${POSIX_LOWER}"/ ;;
  "palpha") awk ${excl}/"${POSIX_ALPHA}"/ ;;
  "pdigit") awk ${excl}/"${POSIX_DIGIT}"/ ;;
  "palnum") awk ${excl}/"${POSIX_ALNUM}"/ ;;
  "punct") awk ${excl}/"${POSIX_PUNCT}"/ ;;
  "pspace") awk ${excl}/"${POSIX_SPACE}"/ ;;
  "pword") awk ${excl}/"${POSIX_WORD}"/ ;;
  *) awk ${excl}/"${opt}"/ ;;
  esac
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
# TESTING NEEDED FOR EVERYTHING BELOW
## ---------------------------------------------
# datetime:
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
  esac
}
# ------------------------------
# file stuff
function filemod() {
  local opt="${1}"
  shift

  f.read() { cat $1; }
  f.write() { local f="$1"; shift; print "$@" >| "$f"; }
  # shellcheck disable=1009,1072,1073
  f.append() { local f="$1"; shift; print "$@" >>| "$f"; }
  f.copy() { local f="$1"; shift; /bin/cp "$f" "$2"; }
  f.newfile() { touch "$@"; }
  f.backup() { cp "${1}"{,.bak}; }
  f.restore() { cp "${1}"{.bak,} && rm "${1}.bak"; }
  f.exists() { [[ -s "${1}" ]]; }
  f.isempty() { [[ -a "${1}" ]] && [[ ! -s "${1}" ]]; }

  case "$opt" in
    read) f.read "${2}" ;;
    write) f.write "${@}" ;;
    append) f.append "${@}" ;;
    copyto) f.copy "${@}" ;;
    newfile) f.newfile "${@}" ;;
    backup) f.backup "${2}";;
    restore) f.restore "${2}" ;;
    exists) f.exists "${2}" ;;
    isempty) f.isempty "${2}" ;;
  esac
}
function dirmod() {
  dir.new() { mkdir "${1}"; }
  dir.read() { ls "${1}"; }
  dir.backup() { cp -r "${1}" "${1}.bak"; }
  dir.restore() { cp -r "${1}.bak" "${1}" && rm -rf "${1}.bak"; }
  dir.parent() { dirname "${1:-(pwd)}"; }
  dir.exists() { [[ -d "${1}" ]]; } 
  dir.isempty() { 
    local count=$(ls -la "${1}" | wc -l | trim.left) 
    [[ $count -eq 0 ]];  
  }
  case "$1" in
    new) dir.new "${2}" ;;
    read) dir.read "${2}" ;;
    backup) dir.backup "${2}" ;;
    restore) dir.restore "${2}" ;;
    parent) dir.parent "${2}" ;;
    exists) dir.exists "${2}" ;;
    isempty) dir.isempty "${2}" ;;
  esac
}
function fspath() {
  fs.path() { print "$(pwd)/${1}"; }
  fs.abs() { print "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
  fs.newer() { [[ "${1}" -nt "${2}" ]]; }
  fs.older() { [[ "${1}" -ot "${2}" ]]; }
  case "$1" in
    path) fs.path "${2}" ;;
    abs) fs.abs "${2}" ;;
    newer) fs.newer "${2}" "${3}" ;;
    older) fs.older "${2}" "${3}" ;;
  esac
}
## ---------------------------------------------
# END TESTING NEEDED
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
