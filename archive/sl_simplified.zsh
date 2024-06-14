# for sl lang
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
function safequote() {
  local input="$1"
  local quoted=""

  # Escape special characters
  quoted=$(printf '%q' "$input")

  # Return the safely quoted string
  echo "$quoted"
}