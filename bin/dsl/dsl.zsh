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
DSL_DIR="/Users/unforswearing/zsh-config/bin/dsl"
################################################
#  use dsl::disable to unset builtins i never use
dsl::disable() {
  eval "disable -r time until select coproc nocorrect"
}
dsl::unset() {
  # eval "disable -r repeat let if elif else fi for case esac"
}
dsl::compile() {
  cat $DSL_DIR/*.zsh >>| dsl.pkg.zsh
}
################################################
# functions named use::<name> are for dsl internal use.
# the standalone `use` function should be run when loading these 
# in a script file or an interactive zsh session.
# this is done to take advantage of the double colon `::` namespace syntax
# see the `ns` function below
use::dslenv() {
  # these options are already enabled in my interactive zsh sessions
  # add `use::dslenv` to the top of scripts that use dsl
  setopt bsdecho noclobber cprecedences cshjunkieloops 
  setopt kshzerosubscript localloops shwordsplit warncreateglobal
}
use::filepath() { source "${DSL_DIR}/filepath.zsh"; }
use::mathnum() { source "${DSL_DIR}/mathnum.zsh"; }
use::pairs() { source "${DSL_DIR}/pairs.zsh"; }
use::string() { source "${DSL_DIR}/string.zsh"; }
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
  } && green "dsl/patterns loaded"
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
    "::string") use::string ;;
    *) source "$@" ;;
  esac
}
################################################
# send the result of evaluated arguments to dev null
function {discard,quiet}() { eval "$@" >|/dev/null 2>&1; }
# assertions with "is"
# @todo some of these don't work. use a language that has strict typing (TBD)
#   - it would be nice to just use typescript types, ts may be too heavy for just this
is() {
  discard use::string
  discard use::patterns
  unsetopt warn_create_global
  local opt="${1}"
  case "${opt}" in
  "fn")
    local is_function
    is_function=$(type -w "$2" | awk -F: '{print $2}' | trim.left)
    [[ ${is_function} == "function" ]];
    ;;
  "num" | "int")
    [[ "${2}" =~ $RE_NUMBER ]];
    ;;
  "str")
    [[ "${2}" =~ $RE_ALPHA ]];
    ;;
  "set")
    [[ -v "${2}" ]];
    ;;
  "unset" | "null")
    [[ ! -v "${2}" ]] || [[ -z "${2}" ]];
    ;;
  *)
    print "is [fn | num | str | set | unset | null ] <arg>"  
    ;;
  esac
  setopt warn_create_global
}
# declare -rg is="is"
functions["is"]="is" >|/dev/null 2>&1;
alias -g is="is"
################################################
assert() {
  local opt="${1}"
  case "${opt}" in
  "empty_or_null") [[ -z "${2}" || "${2}" == "null" ]] && return 0 || return 1 ;;
  "bool") [[ "${2}" == true || "${2}" == false ]] && return 0 || return 1 ;;
  "true") [[ "${2}" == true || "${2}" -eq 0 ]] && return 0 || return 1 ;;
  "false") [[ "${2}" == false || "${2}" -eq 0 ]] && return 0 || return 1 ;;
  *)
    local left="${1}"
    local right="${3}"
    case "${2}" in
    "eq") print "${left} == ${right}" | bc ;;
    "ne") print "${left} != ${right}" | bc ;;
    "gt") print "${left} > ${right}" | bc ;;
    "lt") print "${left} < ${right}" | bc ;;
    "ge") print "${left} >= ${right}" | bc ;;
    "le") print "${left} <= ${right}" | bc ;;
    "mod") print "scale = 0; (${left} % ${right}) == 0)" | bc ;;
    *) print "${2} is not a valid comparator" ;;
    esac
    ;;
  esac
}
################################################
# use discard instead of nil
# alias -g nil='>/dev/null 2>&1'
# use aliases instead of usual comparisons
alias -g eq='-eq'

alias -g ne='-ne'
alias -g gt='-gt'
alias -g lt='-lt'
alias -g ge='-ge'
alias -g le='-le'
# [[ "a" bef "b" ]] => true
alias -g be='<'
# [[ "a" aft "b" ]] => false
alias -g af='>'
################################################
# perhaps the aliases below should be functions
################################################
# try 1 eq 2 && puts "yes" ||  puts "no"
# try (is fn puts) && puts "yes" || puts "no"
alias -g try='test'
# alias -g ??='&&'
# alias -g ::='||'
alias -g not='!'
################################################
# with file in $(ls) run print $file fin
# with file in $(ls) apply print $file fin
alias -g with='foreach'
alias -g run=';'
alias -g apply=';'
alias -g fin='; end'
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
################################################
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
# a regular variable that can be whatever
def() {
  local name="$1"
  shift
  print "$@" | read "$name"
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
## arrays are readonly
## see 'rs' tool for array stuff
arr() {
  local name="$1"
  local arrarg="$2"
  eval "declare -rga $name=${arrarg[@]}"
}
# arrays will split into their indexes when used as arg
arr.topair() {
  use::pairs
  pair $1 $2
}
arr.tostr() {
  print "$@"
}
################################################
calc() { print "$@" | bc; }
################################################
# { 
#  disable -r time until select coproc nocorrect
# }

discard "use::filepath"
green "dsl loaded"