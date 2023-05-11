# For interactive use.
# Use Lua / Teal to write shell scripts. See zconf/src.
import color
export stdlib="${ZSH_BIN_DIR}/stdlib.zsh"
# ---------------------------------------
function reload() { exec zsh; }
function error() {
  :
}
function sysinfo() {
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
  if [[ $options[$1] == "on" ]]; then
    unsetopt "$1"
  else
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]] && checkopt $1;
}
function async() { ({ eval "$@"; } &) >/dev/null 2>&1; }
################################################
# create pseudo types: nil, num, const, atom
declare -A stdtypes
declare -A nils
function nil() {
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
  local name="$1"
  shift;
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
  local val=$stdtypes["$1"]
  if [[ -z $val ]]; then print "none"; else print "$val"; fi;
}
function isnil() {
  # nil has no value so there is no `get nil` command
  local testval=$nils["$1"]
  if [[ "$testval" != true ]]; then false; else true; fi
}
function isnum() {
  local testval="$(get num $1)"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isconst() {
  local testval="$(get const $1)"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isatom() {
  local testval="$(get atom $1)"
  if [[ -z "$testval" ]]; then false; else true; fi
}
function isfn() {
  type -w "$1" | awk -F: '{print $2}' | trim.left
}
function get() {
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
  # https://unix.stackexchange.com/a/290373
  function getvar() {
    # dont use $ with var
    # getvar PATH
    # todo: hide output if there is no match
    declare -p ${(Mk)parameters:#$1}
  }
  # https://unix.stackexchange.com/a/290373
  function getfn() {
    # todo: hide output if there is no match
    declare -f ${(Mk)functions:#$1}
  }
  ## ---------------------------------------------
  # https://unix.stackexchange.com/a/121892
  function checkopt() {
    print $options[$1]
  }
  function getpath() { print "$(pwd)/${1:-$(cat -)}"; }
  function abspath() {
    print "$(cd "$(dirname ${1:-$(cat -)})" && pwd)/$(basename "${1:-$(cat -)}")";
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
    file) file read "$@" ;;
    dir) dir read "$@" ;;
    path) getpath "$@" ;;
    asbpath) abspath "$@" ;;
    *) color red "$0: no method named '$opt'" ;;
  esac
}
function puts() { print "$@"; }
function putf() {
  local str="$1"
  shift
  printf "$str" "$@"
}
## ---------------------------------------------
function cmd() {
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
    *) color red "$0: no method named '$opt'" ;;
  esac
}
## ---------------------------------------------
function lower() {
  local opt="${1:-$(cat -)}" && \
    print "$opt" | tr '[:upper:]' '[:lower:]';
}
function upper() {
  local opt="${1:-$(cat -)}" && \
    print "$opt" | tr '[:lower:]' '[:upper:]';
}
## ---------------------------------------------
function trim() {
  function trim() {
  local opt="${1:-$(cat -)}" && \
    print "$opt" | trim.left | trim.right;
  }
  function trim.left() {
    local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
  }
  function trim.right() {
    local char=${1:-[:space:]}
    sed "s%[${char//%/\\%}]*$%%"
  }
  local opt="$1"
  shift
  case "$opt" in
    left) trim.left "$@" ;;
    right) trim.right "$@" ;;
    *) trim "$@" ;;
  esac
}
# a string matcher, since the `eq` function only works for numbers
function match() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" == "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  if [[ "$left" == "$right" ]]; then true; else false; fi
}
# a simple replace command
function replace() { sd "$1" "${2:-$(cat -)}"; }
# # strings and arrays can use len ----------------
function len() {
  local item="${1:-$(cat -)}"
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
  # bkp filename.txt => filename.txt.bak
  # restore filename.txt => overwrites filename.txt
  function files() { fd --hidden --type file --maxdepth="${1:-1}"; }
  function file.bkp() { cp "${1:-$(cat -)}"{,.bak}; }
  function file.exists() {
    if [[ -s "${1:-$(cat -)}" ]]; then true; else false; fi;
  }
  function file.copy() { <"${1:-$(cat -)}" | pbcopy; }
  function file.new() { touch "$@"; }
  function file.read() { print "$(<"${1:-$(cat -)}")"; }
  function file.rest() { cp "${1:-$(cat -)}"{.bak,} && rm "${1:-$(cat -)}.bak"; }
  function file.empty() {
    if [[ -a "${1:-$(cat -)}" ]] && [[ ! -s "${1:-$(cat -)}" ]]; then
      true
    else
      false
    fi
  }
  function file.isnewer() {
    if [[ "${1}" -nt "${2}" ]]; then true; else false; fi;
  }
  function file.isolder() {
    if [[ "${1}" -ot "${2}" ]]; then true; else false; fi;
  }
  local opt="$1"
  shift
  case "$opt" in
    list) files "$@" ;;
    backup) file.bkp "$@" ;;
    exists) file.exists "$@" ;;
    copy) file.copy  "$@" ;;
    new) file.new  "$@" ;;
    read) file.read "$@" ;;
    restore) file.rest "$@" ;;
    rmempty) file.rmempty "$@" ;;
    listnew) files.listnew "$@" ;;
    isolder) file.isolder "$@" ;;
    isnewer) file.isnewer "$@" ;;
    *) color red "$0: no method named '$opt'" ;;
  esac
}
# directory actions
function dir() {
  function dir.get() { fd --hidden --type directory --maxdepth="${1:-1}"; }
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
  function dir.read() { ls "${1:-$(cat -)}"; }
  function dir.bkp() { cp -r "${1:-$(cat -)}" "${1:-$(cat -)}.bak"; }
  function dir.rst() {
    cp -r "${1:-$(cat -)}.bak" "${1:-$(cat -)}" && \
      rm -rf "${1:-$(cat -)}.bak";
  }
  function dir.parent() { dirname "${1:-(pwd)}"; }
  function dir.exists() {
    if [[ -d "${1:-$(cat -)}" ]]; then true; else false; fi;
  }
  function dir.isempty() {
    local count=$(ls -la "${1:-$(cat -)}" | wc -l | trim.left)
    if [[ $count -eq 0 ]]; then true; else false; fi;
  }
  function dir.up() {
    case "${1}" in
      "") cd .. || return ;;
      *) cd "$(eval "printf -- '../'%.0s {1..$1}")" || return ;;
    esac
  }
  function dir.isnewer() {
    if [[ "${1:-$(cat -)}" -nt "${2}" ]]; then true; else false; fi;
  }
  function dir.isolder() {
    if [[ "${1:-$(cat -)}" -ot "${2}" ]]; then true; else false; fi;
  }
  local opt="$1"
  shift
  case "$opt" in
    get) dir.get "$@" ;;
    rmempty) dir.rmempty "$@" ;;
    new) dir.new "$@" ;;
    read) dir.read "$@" ;;
    backup) dir.bkp "$@" ;;
    restore) dir.rst "$@" ;;
    parent) dir.parent "$@" ;;
    # previous) ;;
    exists) dir.exists "$@" ;;
    isempty) dir.isempty "$@" ;;
    up) dir.up "$@" ;;
    isolder) dir.isolder "$@" ;;
    isnewer) dir.isnewer "$@" ;;
    *) color red "$0: no method named '$opt'" ;;
  esac
}
# fs prefix works for files and dirs
# filepath.abs "../../file.txt"
# math -------------------------------------------
# all math commands can be used in two ways:
# add 2 2 => 4
# print 2 | add 2 => 4
function add() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  print "$((left + right))";
}
function sub() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  print "$((left - right))";
}
function mul() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  print "$((left * right))";
}
function div() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  print "$((left / right))";
}
function pow() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  print "$((left ** right))";
}
function mod() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  print "$((left % right))";
}
function eq() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  if [[ "$left" -eq "$right" ]]; then true; else false; fi
}
function ne() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  if [[ "$left" -ne "$right" ]]; then true; else false; fi
}
function gt() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  if [[ "$left" -gt "$right" ]]; then true; else false; fi
}
function lt() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  if [[ "$left" -lt "$right" ]]; then true; else false; fi
}
function ge() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  if [[ "$left" -ge "$right" ]]; then true; else false; fi
}
function le() {
  local left=
  local right="${2:-$1}"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  if [[ "$left" -le "$right" ]]; then true; else false; fi
}
function incr() { local opt="${1:-$(cat -)}"; print $((++opt)); }
function decr() { local opt="${1:-$(cat -)}"; print $((--opt)); }
function sum() {
  print "${@:-$(cat -)}" |
      awk '{for(i=1; i<=NF; i++) sum+=$i; } END {print sum}'
}
function calc() { print "$@" | bc; }
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