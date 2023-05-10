# For interactive use.
# Use Lua / Teal to write shell scripts. See zconf/src.
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
    help) print "sysinfo <hist|cpu|disks|mem|temp|net>" ;;
  esac
}
# topt: toggle the option - if on, turn off. if off, turn on
function topt() {
  if [[ $options[$1] == "on" ]]; then
    unsetopt "$1"
  else
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]] && checkopt $1;
}
function memory() { sysinfo memory; }
function async() { ({ eval "$@"; } &) >/dev/null 2>&1; }
################################################
# create pseudo types: nil, num, const, atom
declare -A nils
function nil() {
  # a nil type
  # for sending commands to nothingness, use `cmd discard`
  local name="$1"
  local value="$(cat /dev/null)"
  nils["$name"]=true
  eval "function $name() print $value;"
}
declare -A nums
function num() {
  local name="$1"
  local value="$2"
  nums["$name"]="$((value))"
  eval "function $name() print $value;"
  functions["$name"]
}
# const utencil "spoon"
declare -A consts
function const() {
  local name="$1"
  shift;
  local value="$@"
  declare -rg "$name=$@"
  consts["$name"]="$@"
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
}
# check the type of various vars
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
    if [[ -z $val ]]; then
      false
    else
      print "$val"
    fi;
  }
  function getconst() {
    local val=$consts["$1"]
    if [[ -z $val ]]; then
      false
    else
      print "$val"
    fi;
  }
  function getatom() {
    local val=$atoms["$1"]
    if [[ -z $val ]]; then
      false
    else
      print "$val"
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
    help) print "get <num|const|atom|var|fn|opt|file|dir|path|abspath> name" ;;
  esac
}
function puts() {
  print "$@"
}
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
    *) command "$@" ;;
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
    *) print "count <lines | words | chars>"
  esac
}
function file() {
  # bkp filename.txt => filename.txt.bak
  # restore filename.txt => overwrites filename.txt
  function files() { fd --hidden --type file --maxdepth="${1:-1}"; }
  function file.bkp() { cp "${1:-$(cat -)}"{,.bak}; }
  function file.exists() {
    if [[ -s "${1:-$(cat -)}" ]]; then
      true
    else
      false
    fi
  }
  function file.copy() { <"${1:-$(cat -)}" | pbcopy; }
  function file.new() { touch "$@"; }
  function file.read() { print "$(<"${1:-$(cat -)}")"; }
  function file.rest() { cp "${1:-$(cat -)}"{.bak,} && rm "${1:-$(cat -)}.bak"; }
  function file.rmempty() { find . -type f -empty -print -delete; }
  function files.listnew() {
    # recency=2
    # ls.new $recency
    fd --type file \
      --base-directory $(pwd) \
      --absolute-path \
      --max-depth=1 \
      --threads=2 \
      --change-newer-than "${1:-5}"min
  }
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
    help)
      print "file <backup|exists|copy|new|read|restore|"
      print "      rmempty|listnew|isolder|isnewer> name"
    ;;
    *) files "$@" ;;
  esac
}
# directory actions
function dir() {
  function dir.get() { fd --hidden --type directory --maxdepth="${1:-1}"; }
  function dir.rmempty() { find . -type d -empty -print -delete; }
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
    help)
      print "dir <get|rmempty|new|read|backup|restore|parent|"
      print "     previous|exists|isempty|up|isolder|isnewer> name"
    ;;
    *) dir.get "$@" ;;
  esac
}
function rmempty() { file rmempty && dir rmempty; }
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
## pseudo objects: string and number
## TBD: obj:file, obj:dir
function obj:file() {
  # read, write, append, created, modified, path, copy, rm, close
}
function obj:dir() {
  # read, write, newfile, newdir, path, copy, created, modified, rm, close
}
function obj:number() {
  # a number "object"
  @num() {
    unsetopt warn_create_global
    local name="${1}"
    local value=${2}
    declare -rg $name=$value
    functions[$name]="print ${value}"
    eval "
  function $name { print ${value}; }
  alias -g $name="$name"
  "
    function _n() {
      val="$1"
      function "$name".add() { local opt=$1; add "$val" "$opt" }
      function "$name".sub() { local opt=$1; sub "$val" "$opt" }
      function "$name".mul() { local opt=$1; mul "$val" "$opt" }
      function "$name".div() { local opt=$1; div "$val" "$opt" }
      function "$name".pow() { local opt=$1; pow "$val" "$opt" }
      function "$name".mod() { local opt=$1; mod "$val" "$opt" }
      function "$name".eq() { local opt=$1; eq "$val" "$opt" }
      function "$name".ne() { local opt=$1; ne "$val" "$opt" }
      function "$name".gt() { local opt=$1; gt "$val" "$opt" }
      function "$name".lt() { local opt=$1; lt "$val" "$opt" }
      function "$name".ge() { local opt=$1; ge "$val" "$opt" }
      function "$name".le() { local opt=$1; le "$val" "$opt" }
      function "$name".incr() { incr $val }
      function "$name".decr() { decr $val }
      function "$name".sum() { local args="$@"; sum "$args" }
    }
    _n "$value"
  }
  @num "$@"
}
function obj:string() {
  # a string object
  function @str() {
    unsetopt warn_create_global
    local name="${1}" && shift
    local value="\"${@}\""
    declare -rg $name=$value
    functions[$name]="print ${value}"
    eval "
  function "$name" { print "${value}"; }
  alias -g $name="$name"
  function $name.upper() { print ${value} | upper ; }
  function $name.lower() { print ${value} | lower ; }
  function $name.trim() { print ${value} | trim ; }
  function $name.trim.left() { print ${value} | trim.left ; }
  function $name.trim.right() { print ${value} | trim.right ; }
  function $name.len() { print ${value} | len ; }
  "
  }
  @str "$@"
}
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
