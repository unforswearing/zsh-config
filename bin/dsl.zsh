# @NOTE / @TODO 5/6/2023:
# Much of this code will be replaced with teal / lua and luash. 
#
# send the result of evaluated arguments to dev null
function discard() { eval "$@" >|/dev/null 2>&1; }
################################################
function nil() { >/dev/null 2>&1; }
function puts() {
  print "$@"
}
function putf() {
  local str="$1"
  shift
  printf "$str" "$@"
}
function const() {
  local name="$1"
  shift
  declare -rg "$name=$@"
}
# atom, single item of data. a number or word
# the concept of atoms are taken from elixir
#   - a constant whose value is its name
# eg atom hello => hello=hello
# useage: atom value
function atom() {
  local nameval="$1"
  eval "function $nameval() print $nameval;"
  # if $1 is a number, don't use declare
  declare -rg $nameval="$nameval"
  functions["$nameval"]="$nameval" >|/dev/null 2>&1;
}
function isfn() {
  type -w "$1" | awk -F: '{print $2}' | trim.left
}
# https://unix.stackexchange.com/a/290373
function getvar() {
  # todo: hide output if there is no match
  declare -p ${(Mk)parameters:#$1}
}
# https://unix.stackexchange.com/a/290373
function getfn() {
  # todo: hide output if there is no match, replacing the head -n 1 command
  declare -f ${(Mk)functions:#$1}
}
# https://unix.stackexchange.com/a/121892
function checkopt() {
  print $options[$1]
}
# topt: toggle the option - if on, turn off. if off, turn on
function topt() {
  if [[ $options[$1] == "on" ]]; then
    unsetopt "$1"
  else
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]] && checkopt $1
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
# a simple replace command
function replace() { sd "$1" "${2:-$(cat -)}"; }
# # strings and arrays can use len ----------------
function len() {
  local item="${1:-$(cat -)}"
  print "${#item}"
}
function count.lines() { local opt="${1:-$(cat -)}" && print "$opt" | wc -l | trim; }
function count.words() { local opt="${1:-$(cat -)}" && print "$opt" | wc -w | trim; }
function count.chars() { local opt="${1:-$(cat -)}" && print "$opt" | wc -m | trim; }
# file.backup filename.txt => filename.txt.bak
# file.restore filename.txt => overwrites filename.txt
function newfile() { touch "$@"; }
function readfile() { print "$(<"${1:-$(cat -)}")"; }
function copy() { <"${1:-$(cat -)}" | pbcopy; }
function bkp() { cp "${1:-$(cat -)}"{,.bak}; }
function restore() { cp "${1:-$(cat -)}"{.bak,} && rm "${1:-$(cat -)}.bak"; }
function fileexists() { [[ -s "${1:-$(cat -)}" ]]; }
function fileempty() { [[ -a "${1:-$(cat -)}" ]] && [[ ! -s "${1:-$(cat -)}" ]]; }
# directory actions
function newdir() { mkdir "${1:-$(cat -)}"; }
function readdir() { ls "${1:-$(cat -)}"; }
function dirbkp() { cp -r "${1:-$(cat -)}" "${1:-$(cat -)}.bak"; }
function dirrst() { 
  cp -r "${1:-$(cat -)}.bak" "${1:-$(cat -)}" && \
    rm -rf "${1:-$(cat -)}.bak"; 
}
function parentdir() { dirname "${1:-(pwd)}"; }
function direxists() { [[ -d "${1:-$(cat -)}" ]]; }
function dirempty() {
  local count=$(ls -la "${1:-$(cat -)}" | wc -l | trim.left)
  [[ $count -eq 0 ]];
}
# fs prefix works for files and dirs
# filepath.abs "../../file.txt"
function getpath() { print "$(pwd)/${1:-$(cat -)}"; }
function getabs() { 
  print "$(cd "$(dirname ${1:-$(cat -)})" && pwd)/$(basename "${1:-$(cat -)}")"; 
}
function isnewer() { [[ "${1:-$(cat -)}" -nt "${2}" ]]; }
function isolder() { [[ "${1:-$(cat -)}" -ot "${2}" ]]; }
# math -------------------------------------------
function add() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  print "$((left + right))";
}
function sub() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  print "$((left - right))";
}
function mul() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  print "$((left * right))";
}
function div() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  print "$((left / right))";
}
function pow() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  print "$((left ** right))";
}
function mod() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  print "$((left % right))";
}
function eq() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  return "$((left == right))";
}
function ne() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  return "$((left != right))";
}
function gt() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  return "$((left > right))";
}
function lt() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  return "$((left < right))";
}
function ge() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  return "$((left >= right))";
}
function le() {
  local left="${1}";
  local right="${2:-$(cat -)}";
  return "$((left <= right))";
}
function ++() { local opt="${1:-$(cat -)}"; print $((++opt)); }
function --() { local opt="${1:-$(cat -)}"; print $((--opt)); }
function sum() {
  print "${@:-$(cat -)}" |
      awk '{for(i=1; i<=NF; i++) sum+=$i; } END {print sum}'
}
## ---------------------------------------------
function calc() { print "$@" | bc; }
## ---------------------------------------------
function async() { ({eval "$@";}&) >|/dev/null 2>&1; }
## ---------------------------------------------
function use() {
  local opt="$1"
  shift
  function use::number() {
    ## a number "object"
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
    functions["@num"]="@num"
    alias -g @num="@num"
  }
  ## ---------------------------------------------
  function use::pairs() {
    ## a very simple data structure --------------------------
    pair() {
      print "${1};${2}"
    }
    pair.cons() {
      print "${1:-$(cat -)}" | awk -F";" '{print $1}'
    }
    pair.cdr() {
      print "${1:-$(cat -)}" | awk -F";" '{print $2}'
    }
    pair.setcons() {
      print "$1" | sed 's/^.*;/'"$2"';/'
    }
    pair.setcdr() {
      print "$1" | sed 's/;.*$/;'"$2"'/'
    }
    # change ; to \n so pair can be used with loops
    pair.iter() {
    }
    pair.torange() {
      range $(pair.cons "$1") $(pair.cdr "$1")
    }
    pair.torange.reverse() {
      range $(pair.cdr "$1") $(pair.cons "$1")
    }
    pair.tovar() {
      atom $(pair.cons "$1") $(pair.cdr "$1")
    }
  }
  ## ---------------------------------------------
  function use::range() {
    # formatted ranges
    # do not quote - range can be alpha or num
    #  - maybe: range int $1 $2 / range str "$1" "$2"
    # todo: incorporate seq and / or jot to do more stuff
    # also: https://linuxize.com/post/bash-sequence-expression/
    range() {
      local incrementor="..${3:-1}"
      print {$1..$2$incrementor}
    }
    # a range of integers
    range.int() {;}
    # a range of letters
    range.str() {;}
    # range.wrap "a" 4 5 "zz" => a4zz a5zz
    range.wrap() {;}
    range.nl() {
      local incrementor="..${3:-1}"
      print {$1..$2$incrementor} | tr ' ' '\n'
    }
    range.rev() {
      local incrementor="..${3:-1}"
      print {$1..$2$incrementor} | tr ' ' '\n' | sort -r
    }
  }
  ## ---------------------------------------------
  function use::string() {
    # DSL STRING
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
    functions["@str"]="@str"
    alias -g @str="@str"
  }
  case "$opt" in
    "number") use::number ;;
    "pairs") use::pairs ;;
    "range") use::range ;;
    "string") use::string ;;
    "dsl")
      use::number
      use::pairs
      use::range
      use::string
    ;;
    "clipboard") source <(pbpaste) ;;
    *) source "$@" ;;
  esac
}
