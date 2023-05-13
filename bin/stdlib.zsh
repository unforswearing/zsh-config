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
import color
export stdlib="${ZSH_BIN_DIR}/stdlib.zsh"
function reload() { exec zsh; }
function libreload() { source "${stdlib}"; }
# usage libutil:argtest num
# libutil:argtest 2 => if $1 or $2 is not present, print message
function libutil:argtest() { 
  setopt errreturn
  local caller=$funcstack[2];
  if [[ -z "$1" ]]; then 
    color red "$caller: argument missing"; 
    return 1
  fi; 
}
# ---------------------------------------
function error() {
  :
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
    *) color red "$0: no method named '$opt'" ;;
  esac
}
function memory() { sysinfo memory; }
# topt: toggle the option - if on, turn off. if off, turn on
function topt() {
  libutil:argtest "$1"
  if [[ $options[$1] == "on" ]]; then
    unsetopt "$1"
  else
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]] && checkopt $1;
}
################################################
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
  local name="$1"
  shift;
  libutil:argtest "$@"
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
  declare -rg $nameval="$nameval" >|/dev/null 2>&1;
  functions["$nameval"]="$nameval" >|/dev/null 2>&1;
  atoms["$nameval"]="$nameval" >|/dev/null 2>&1;
  stdtypes["$name"]="atom"
}
# check the type of various vars
function typeof() {
  libutil:argtest "$1"
  local val=$stdtypes["$1"]
  if [[ -z $val ]]; then print "none"; else print "$val"; fi;
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
  type -w "$1" | awk -F: '{print $2}' | trim.left
}
function get() {
  libutil:argtest "$1"
  function getnum() {
    local val=$nums["$1"]
    if [[ -z $val ]]; then false; else print "$val";
    fi;
  }
  function getconst() {
    local val=$consts["$1"]
    if [[ -z $val ]]; then false; else print "$val";
    fi;
  }
  function getatom() {
    local val=$atoms["$1"]
    if [[ -z $val ]]; then false; else print "$val";
    fi;
  }
  function getvar() {
    # dont use $ with var
    # getvar PATH
    # todo: hide output if there is no match
    local value=$(eval "print \$"${1}"")
    if [[ -z "$value" ]]; then
      color red "$0: $1 not found"
    else
      print "$value"
    fi
  }
  function getfn() {
    # todo: hide output if there is no match
   declare -f "$1"
  }
  ## ---------------------------------------------
  # https://unix.stackexchange.com/a/121892
  function checkopt() {
    print $options[$1]
  }
  local opt="$1"
  shift
  case "$opt" in
    num) getnum "$@" ;;
    const) getconst "$@" ;;
    atom) getatom "$@" ;;
    var) getvar "$@" ;;
    fn) getfn "$@" ;;
    opt) checkopt "$@" ;;
    *) color red "$0: no method named '$opt'" && return 1 ;;
  esac
}
function puts() { print "$@"; }
function putf() {
  libutil:argtest "$1"
  # libutil:argtest "$1" 2
  local str="$1"
  shift
  printf "$str" "$@"
}
## ---------------------------------------------
function cmd() {
  libutil:argtest "$1"
  function cpl() {
    unsetopt warn_create_global
    OIFS="$IFS"
    IFS=$'\n\t'
    local comm=$(history | gtail -n 1 | awk '{first=$1; $1=""; print $0;}')
    echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"
    IFS="$OIFS"
    setopt warn_create_global
  }
  function discard() { eval "$@" >|/dev/null 2>&1; }
  function require() {
    hash "$1" 2>/dev/null && true || {
      echo >&2 "Error: '$1' is required, but was not found."
   }
  }
  local opt="$1"
  shift
  case "$opt" in
    last) cpl ;;
    require) require "$@" ;;
    discard) discard "$@" ;;
    help) print "cmd [last|require|discard] name" ;;
    *) color red "$0: no method named '$opt'" && return 1 ;;
  esac
}
## ---------------------------------------------
function lower() {
  local opt="${1}" && \
    print "$opt" | tr '[:upper:]' '[:lower:]' || \
    color red "$0: missing argument";
}
function upper() {
  local opt="${1}" && \
    print "$opt" | tr '[:lower:]' '[:upper:]' || \
    color red "$0: missing argument";
}
## ---------------------------------------------
function trim() {
  function trim() {
  local opt="${1}" && \
    print "$opt" | trim.left | trim.right || \
    color red "$0: missing argument";
  }
  function trim.left() {
    local char=[:space:]
    sed "s%^[${char//%/\\%}]*%%"
  }
  function trim.right() {
    local char=[:space:]
    sed "s%[${char//%/\\%}]*$%%"
  }
  local opt="$1"
  case "$opt" in
    left) trim.left "$@" ;;
    right) trim.right "$@" ;;
    *) trim "$@" ;;
  esac
}
function contains() { 
  # using nushell
  libutil:argtest "$1"
  local result=$(nu -c "echo $(cat -) | str contains $@")
  if [[ $result == "true" ]]; then true; else false; fi;
}
# a string matcher, since the `eq` function only works for numbers
# match will check the entire string. use contains for string parts
function match() {
  libutil:argtest "$1"
  local left="${1}"
  local right="${2}"
  if [[ "$left" == "$right" ]]; then true; else false; fi
}
# a simple replace command
function replace() { 
  libutil:argtest "$1"
  sd "$1" "${2}"; 
}
# # strings and arrays can use len ----------------
function len() {
  libutil:argtest "$1"
  local item="${1}"
  print "${#item}"
}
function count() {
  function count.lines() {
    local opt="${1:-$(cat -)}" && print "$opt" | wc -l | trim;
  }
  function count.words() {
    local opt="${1:-$(cat -)}" && print "$opt" | wc -w | trim;
  }
  function count.chars() {
    local opt="${1:-$(cat -)}" && print "$opt" | wc -m | trim;
  }
  local opt="$1"
  shift
  case "$opt" in
    lines) count.lines  "$@" ;;
    words) count.words "$@" ;;
    chars) count.chars "$@" ;;
    *) color red "$0: no method named '$opt'" ;;
  esac
}
function file() {
  libutil:argtest "$1"
  # bkp filename.txt => filename.txt.bak
  # restore filename.txt => overwrites filename.txt
  function file.bkp() { 
    cp "${1}"{,.bak}; 
  }
  function file.exists() {
    if [[ -s "${1}" ]]; then true; else false; fi;
  }
  function file.copy() { 
    <"${1}" | pbcopy; 
  }
  function file.read() { 
    print "$(<${1})"; 
  }
  function file.rest() { 
    cp "${1}"{.bak,} && rm "${1}.bak"; 
  }
  function file.empty() {
    if [[ -a "${1}" ]] && [[ ! -s "${1}" ]]; then
      true
    else
      false
    fi
  }
  function file.isnewer() {
    libutil:argtest "$1"
    if [[ "${1}" -nt "${2}" ]]; then true; else false; fi;
  }
  function file.isolder() {
    libutil:argtest "$1"
    if [[ "${1}" -ot "${2}" ]]; then true; else false; fi;
  } 
  local opt="$1"
  shift
  case "$opt" in
    backup) file.bkp "$@" ;;
    exists) file.exists "$@" ;;
    copy) file.copy  "$@" ;;
    read) file.read "$@" ;;
    restore) file.rest "$@" ;;
    isempty) file.empty "$0" ;;
    isolder) file.isolder "$@" ;;
    isnewer) file.isnewer "$@" ;;
    *) color red "$0: no method named '$opt'" && return 1;;
  esac
}
# directory actions
function dir() {
  libutil:argtest "$1"
  function dir.new() {
    ccd() { mkdir -p "$1" && cd "$1"; }
    # mkdir "$@";
    case "$1" in
    "cd")
      shift
      ccd "$1"
      ;;
    *) mkdir "$@" ;;
    esac
  }
  function dir.bkp() { 
    cp -r "${1}" "${1}.bak"; 
  }
  function dir.rst() {
    cp -r "${1}.bak" "${1}" && rm -rf "${1}.bak";
  }
  function dir.parent() { dirname "${1}"; }
  function dir.exists() {
    if [[ -d "${1}" ]]; then true; else false; fi;
  }
  function dir.isempty() {
    local count=$(ls -la "${1}" | wc -l | trim.left)
    if [[ $count -eq 0 ]]; then true; else false; fi;
  }
  function dir.up() {
    libutil:argtest "$1"
    case "${1}" in
      "") cd .. || return ;;
      *) cd "$(eval "printf -- '../'%.0s {1..$1}")" || return ;;
    esac
  }
  function dir.isnewer() {
    if [[ "${1}" -nt "${2}" ]]; then true; else false; fi;
  }
  function dir.isolder() {
    if [[ "${1}" -ot "${2}" ]]; then true; else false; fi;
  }
  local opt="$1"
  shift
  case "$opt" in
    new) dir.new "$@" ;;
    backup) dir.bkp "$@" ;;
    restore) dir.rst "$@" ;;
    parent) dir.parent "$@" ;;
    # previous) ;;
    exists) dir.exists "$@" ;;
    isempty) dir.isempty "$@" ;;
    up) dir.up "$@" ;;
    isolder) dir.isolder "$@" ;;
    isnewer) dir.isnewer "$@" ;;
    *) color red "$0: no method named '$opt'" && return 1 ;;
  esac
}
# fs prefix works for files and dirs
# filepath.abs "../../file.txt"
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
  print "$((left + right))";
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
  print "$((left - right))";
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
  print "$((left * right))";
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
  print "$((left / right))";
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
  print "$((left ** right))";
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
  print "$((left % right))";
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
  local opt="${1:-$(cat -)}"; 
  libutil:argtest "$opt"
  print $((++opt)); 
}
function decr() { 
  local opt="${1:-$(cat -)}"; 
  libutil:argtest "$opt"
  print $((--opt)); 
}
function sum() {
  local valueargs="${@:-$(cat -)}" 
  libutil:argtest "$valueargs"
  print "${valueargs}" |
      awk '{for(i=1; i<=NF; i++) sum+=$i; } END {print sum}'
}
function calc() { 
  libutil:argtest "$1"
  print "$@" | bc; 
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
  local bindir="/Users/unforswearing/zsh-config/src/bin"
  path+="$bindir"

  local functionname="${1}"
  local functionbody=$(get fn $functionname)

  local binfile="${bindir}/${functionname}"
  local argitems=("\\"" "$" "@" "\\"")

  puts "#!/opt/local/bin/zsh" >| "$binfile"

  {
    puts "source \"${stdlib}\"";
    puts "$functionbody";
    puts "$functionname \"$(puts $argitems | sd " " "")\"";
  } >>| "$binfile"

  chmod +x "$binfile"
}
generate_binfile "generate_binfile"
generate_binfile "delete_binfiles"