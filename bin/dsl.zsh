# @todo split dsl into loadable modules, create loader function
#
# this file contains code that attempts to make zsh more like a 
# traditional programming language via new keywords, env variables, and "objects"
# NB. use this DSL in scripts, not interactively!
# 
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
# Notes from Zsh documentation --------------------------------------
# 6.5 Reserved Words
# The following words are recognized as reserved words when 
# used as the first word of a
# command unless quoted or disabled using disable -r:
#   do done esac then elif else fi for case if while function repeat time until
#   select coproc nocorrect foreach end ! [[ { } declare export float integer
#   local readonly typeset
# Additionally, ‘}’ is recognized in any position if neither 
# the IGNORE_BRACES option nor the
# IGNORE_CLOSE_BRACES option is set.
# ------------------------------------------------------------------
## DSL MAIN ========================================================
# DSL_DIR="/Users/unforswearing/zsh-config/bin/dsl"
## ---------------------------------------------
#  use dsl::disable to unset builtins i never use
dsl::disable() {
  eval "disable -r time until select coproc nocorrect"
}
dsl::unset() {
  # eval "disable -r repeat let if elif else fi for case esac"
}
dsl::compile() {
  cat $DSL_DIR/*.zsh >>| dsl.pkg.zsh;
}
## ---------------------------------------------
# send the result of evaluated arguments to dev null
function {discard,quiet}() { eval "$@" >|/dev/null 2>&1; }
################################################
alias -g nil='>/dev/null 2>&1'
# use aliases instead of usual comparisons
alias -g eq='-eq'
alias -g ne='-ne'
alias -g gt='-gt'
alias -g lt='-lt'
alias -g ge='-ge'
alias -g le='-le'
# [[ "a" be "b" ]] => true
alias -g be='<'
# [[ "a" af "b" ]] => false
alias -g af='>'
################################################
# perhaps the aliases below should be functions
################################################
# try 1 eq 2 && puts "yes" ||  puts "no"
# try (is fn puts) && puts "yes" || puts "no"
alias -g try='test'
# alias -g ??='&&'
# alias -g ::='||'
# alias -g not='!'
################################################
# with file in $(ls) run print $file fin
# with file in $(ls) apply print $file fin
alias -g with='foreach'
alias -g run=';'
alias -g apply=';'
alias -g nop='; end'
################################################
# i/o
puts() {
  print "$@"
}
putf() {
  local str="$1"
  shift
  printf "$str" "$@"  
}
getinput() {
  # get user input, with options
  read "inputvar?$1"
}
# write file.txt "ls"
write() {
  local file="$1"
  shift
  eval "$@" >| "$file"
}
# append file.txt "print file stuff"
append() {
  local file="$1"
  shift
  eval "$@" >> "$file"
}
## ---------------------------------------------
# use ns to load vars and functions into an environment
# ns == "name space", basically the same as source
# except they must be called using `::name`
ns() {
  local name="$1"
  shift
  local nsbody="$@"
  eval "function ::$name() { $nsbody; }"
}
# fn for keyword shorthand
fn() {
  local name="$1"
  shift
  local fnbody="$@"
  eval "function $name() { $fnbody; }"
}
const() {
  local name="$1"
  shift
  declare -rg "$name=$@"
}
global() {
  local name="$1"
  shift
  local value="$@"

}
# a regular variable that can be whatever
def() {
  unsetopt warncreateglobal
  local name="$1"
  shift
  print "$@" | read "$name"
}
# meta name mtype="string"
# meta name mtype="list"
# meta name mtype="integer"
meta() {
  # todo
}
# atom, single item of data. a number or word
# the concept of atoms are taken from elixir 
#   - a constant whose value is its name
# eg atom hello => hello=hello
# useage: atom value
atom() {
  local nameval="$1"
  eval "function $nameval() print $nameval;"
  # if $1 is a number, don't use declare 
  declare -rg $nameval="$nameval"
  functions["$nameval"]="$nameval" >|/dev/null 2>&1;
}
isfn() {
  type -w "$1" | awk -F: '{print $2}' | trim.left
}
# https://unix.stackexchange.com/a/290373
getvar() {
  # todo: hide output if there is no match
  declare -p ${(Mk)parameters:#$1}
}
# https://unix.stackexchange.com/a/290373
getfn() {
  # todo: hide output if there is no match, replacing the head -n 1 command
  declare -f ${(Mk)functions:#$1} 
}
# https://unix.stackexchange.com/a/121892
checkopt() {
  print $options[$1]
}
# topt: toggle the option - if on, turn off. if off, turn on
topt() {
  if [[ $options[$1] == "on" ]]; then
    unsetopt "$1"
  else 
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]] && checkopt $1
}
## ---------------------------------------------
calc() { print "$@" | bc; }
## ---------------------------------------------
async() { ({eval "$@";}&) >|/dev/null 2>&1; }
## ---------------------------------------------
use::filepath() { 
  use::string >|/dev/null 2>&1
  ## ---------------------------------------------
  # DSL FS
  alias ll='exa $EXA_DEFAULT_OPTIONS'
  alias ll.bw='exa $EXA_DEFAULT_OPTIONS --color=never'
  alias ll.r='exa $EXA_DEFAULT_OPTIONS -R'
  # file.backup filename.txt => filename.txt.bak
  # file.restore filename.txt => overwrites filename.txt
  function {newfile,fs.file.new}() { touch "$@"; }
  function {readfile,fs.file.read}() { print "$(<"$1")"; }
  function {copy,fs.file.copy}() { file.read "$1" | pbcopy; }
  function {bkp,fs.file.backup}() { cp "${1}"{,.bak}; }
  function {rst,fs.file.restore}() { cp "${1}"{.bak,} && rm "${1}.bak"; }
  function {fexists,fs.file.exists}() { [[ -s "${1}" ]]; }
  function {fempty,fs.file.isempty}() { [[ -a "${1}" ]] && [[ ! -s "${1}" ]]; }
  # directory actions
  function {newdir,fs.dir.new}() { mkdir "${1}"; }
  function {readdir,fs.dir.read}() { ls "${1}"; }
  function {dbkp,fs.dir.backup}() { cp -r "${1}" "${1}.bak"; }
  function {drst,fs.dir.restore}() { cp -r "${1}.bak" "${1}" && rm -rf "${1}.bak"; }
  function {pdir,fs.dir.parent}() { dirname "${1:-(pwd)}"; }
  function {dexists,fs.dir.exists}() { [[ -d "${1}" ]]; } 
  function {dempty,fs.dir.isempty}() { 
    local count=$(ls -la "${1}" | wc -l | trim.left) 
    [[ $count -eq 0 ]];  
  }
  # fs prefix works for files and dirs
  # filepath.abs "../../file.txt"
  fs.path() { print "$(pwd)/${1}"; }
  fs.abs() { print "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
  fs.newer() { [[ "${1}" -nt "${2}" ]]; }
  fs.older() { [[ "${1}" -ot "${2}" ]]; }
}
## ---------------------------------------------
use::mathnum() { 
  # DSL MATHNUM
  # math -------------------------------------------
  function {add,math.add}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    print "$((left + right))"; 
  }
  function {sub,math.sub}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    print "$((left - right))"; 
  }
  function {mul,math.mul}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    print "$((left * right))"; 
  }
  function {div,math.div}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    print "$((left / right))"; 
  }
  function {pow,math.pow}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    print "$((left ** right))"; 
  }
  function {mod,math.mod}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    print "$((left % right))"; 
  }
  function {eq,math.eq}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    return "$((left == right))"; 
  }
  function {ne,math.ne}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    return "$((left != right))"; 
  }
  function {gt,math.gt}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    return "$((left > right))"; 
  }
  function {lt,math.lt}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    return "$((left < right))"; 
  }
  function {ge,math.ge}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    return "$((left >= right))"; 
  }
  function {le,math.le}() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    return "$((left <= right))"; 
  }
  function {incr,++}() { local opt="${1:-$(cat -)}"; print $((++opt)); }
  function {decr,--}() { local opt="${1:-$(cat -)}"; print $((--opt)); }
  sum() { 
    print "${@:-$(cat -)}" | 
        awk '{for(i=1; i<=NF; i++) sum+=$i; } END {print sum}' 
  }
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
      function "$name".add() { local opt=$1; math.add "$val" "$opt" }
      function "$name".sub() { local opt=$1; math.sub "$val" "$opt" }
      function "$name".mul() { local opt=$1; math.mul "$val" "$opt" }
      function "$name".div() { local opt=$1; math.div "$val" "$opt" }
      function "$name".pow() { local opt=$1; math.pow "$val" "$opt" }
      function "$name".mod() { local opt=$1; math.mod "$val" "$opt" }
      function "$name".eq() { local opt=$1; math.eq "$val" "$opt" }
      function "$name".ne() { local opt=$1; math.ne "$val" "$opt" }
      function "$name".gt() { local opt=$1; math.gt "$val" "$opt" }
      function "$name".lt() { local opt=$1; math.lt "$val" "$opt" }
      function "$name".ge() { local opt=$1; math.ge "$val" "$opt" }
      function "$name".le() { local opt=$1; math.le "$val" "$opt" }
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
use::pairs() { 
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
use::range() { 
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
use::string() { 
  # DSL STRING
  ## ---------------------------------------------
  lower() { tr '[:upper:]' '[:lower:]'; }
  upper() { tr '[:lower:]' '[:upper:]'; }
  ## ---------------------------------------------
  trim() { trim.left | trim.right; }
  trim.left() {
    local char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
  }
  trim.right() {
    local char=${1:-[:space:]}
    sed "s%[${char//%/\\%}]*$%%"
  }
  # a simple replace command
  replace() { sd "$1" "${2:-$(cat -)}"; }
  # # strings and arrays can use len ----------------
  len() {
    local item="${1:-$(cat -)}"
    print "${#item}"
  }
  ## string "objects"
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
  ## ---------------------------------------------
  count.lines() { wc -l | trim; }
  count.words() { wc -w | trim; }
  count.chars() { wc -m | trim; }
}
## ---------------------------------------------
use::dslenv() {
  # these options are already enabled in my interactive zsh sessions
  # add `use::dslenv` to the top of scripts that use dsl
  setopt bsdecho noclobber cprecedences cshjunkieloops 
  setopt kshzerosubscript localloops shwordsplit warncreateglobal
}
use::patterns() { 
  {
    declare -rg RE_ALPHA="[aA-zZ]"
    declare -rg RE_STRING="([aA-zZ]|[0-9])+"
    declare -rg RE_WORD="\w"
    declare -rg RE_NUMBER="^[0-9]+$"
    declare -rg RE_NUMERIC="^[0-9]+$"
    declare -rg RE_NEWLINE="\n"
    declare -rg RE_SPACE=" "
    declare -rg RE_TAB="\t"
    declare -rg RE_WHITESPACE="\s"
    declare -rg POSIX_UPPER="[:upper:]"
    declare -rg POSIX_LOWER="[:lower:]"
    declare -rg POSIX_ALPHA="[:alpha:]"
    declare -rg POSIX_DIGIT="[:digit:]"
    declare -rg POSIX_ALNUM="[:alnum:]"
    declare -rg POSIX_PUNCT="[:punct:]"
    declare -rg POSIX_SPACE="[:space:]"
    declare -rg POSIX_WORD="[:word:]"
  } 
}
use() {
  local opt="$1"
  shift
  case "$opt" in
    "::dslenv") use::dslenv ;;
    "::filepath") use::filepath ;;
    "::mathnum") use::mathnum ;;
    "::pairs") use::pairs ;;
    "::patterns") use::patterns ;;
    "::range") use::range ;;
    "::string") use::string ;;
    "::dsl") 
      # use::dslenv
      use::filepath
      use::mathnum
      use::pairs
      use::patterns
      use::range
      use::string
    ;;
    "::clipboard") source <(pbpaste) ;;
    *) source "$@" ;;
  esac
}
