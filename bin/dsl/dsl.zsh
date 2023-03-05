# @todo split dsl into loadable modules, create loader function
# DSL.ZSH
# this file contains code that attempts to make zsh more like a 
# traditional programming language via new keywords, env variables, and "objects"
# NB. use this DSL in scripts, not interactively!

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
###
## DSL MAIN (this file. Loader function TBD)
DSL_DIR="/Users/unforswearing/zsh-config/bin/dsl"
ns::disable() {
  eval "disable -r let if elif else fi for case esac"
  eval "disable -r repeat time until select coproc nocorrect"
}
ns::filepath() { source "${DSL_DIR}/filepath.zsh"; }
ns::mathnum() { source "${DSL_DIR}/mathnum.zsh"; }
ns::string() { source "${DSL_DIR}/string.zsh"; }
################
export RE_ALPHA="[aA-zZ]"
export RE_STRING="([aA-zZ]|[0-9])+"
export RE_WORD="\w"
export RE_NUMBER="^[0-9]+$"
export RE_NUMERIC="^[0-9]+$"
export RE_NEWLINE="\n"
export RE_SPACE=" "
export RE_TAB="\t"
export RE_WHITESPACE="\s"
export POSIX_UPPER="[:upper:]"
export POSIX_LOWER="[:lower:]"
export POSIX_ALPHA="[:alpha:]"
export POSIX_DIGIT="[:digit:]"
export POSIX_ALNUM="[:alnum:]"
export POSIX_PUNCT="[:punct:]"
export POSIX_SPACE="[:space:]"
export POSIX_WORD="[:word:]"
# ----------------
# from various githubs and gists around the internet
confirm() {
  vared -p  "Are you sure? [y/N] " -c response
  case "$response" in
    [yY][eE][sS]|[yY])
      true
    ;;
    *) false ;;
    esac
}
################
# # typecheck -------------------------------------------
is() {
  unsetopt warn_create_global
  local opt="${1}"
  case "${opt}" in
  "function" | "fun")
    local is_function
    is_function=$(type -w "$2" | awk -F: '{print $2}' | trim.left)
    [[ ${is_function} == "function" ]] && print true || print false
    ;;
  "number" | "num" | "int")
    [[ "${2}" =~ $RE_NUMBER ]] && print true || print false
    ;;
  "string" | "str")
    [[ "${2}" =~ $RE_ALPHA ]] && print true || print false
    ;;
  "set" | "declared" | "decl")
    local alt_opt="${2}"
    [[ -n $alt_opt ]] && print true || print false
    ;;
  "unset" | "empty")
    local alt_opt="${2}"
    [[ -z $alt_opt ]] && print true || print false
    ;;
  "empty_or_null" | "empty" | "null") 
    [[ -z "${2}" || "${2}" == "null" ]] && {
      print false 
    } || {
      print true
    }
    ;;
  # the 'test_truth_string' function will only load
  # if "$opt" is true or false. the ';&' at the end of 
  # this section is a pass through -- test_truth_string
  # is available in the context of options "true" and "false"
  "true" | "false")
    test_truth_string() {
      test "$1" == "true" && print true || print false
    }
    test_truth_number() {
      test "$1" -eq 0 && print true || print false
    }
    ;&
  "true")
    test $(is string "${2}") == true && {
      test_truth_string "${2}" 
    } || {
      test_truth_number "${2}"
    }
    ;;
  "false")
    test $(is string "${2}") == true && {
      test_truth_string "${2}" 
    } || {
      test_truth_number "${2}"
    }
    ;;
  "bool") print "bool is not a valid option." ;;
  *)
    [[ "${1}" =~ ${2} ]] && print true || print false
    ;;
  esac
  setopt warn_create_global
}
# declare -rg is="is"
functions["is"]="is"  
alias -g is="is"
##

alias -g nil='>/dev/null 2>&1'
# try 1 -eq 2 ? print "yes" :: print "no"
alias -g try='test'
alias -g ?='&&'
alias -g ::='||'
alias -g not='!'

alias -g use='source'

# with file in $(ls) run print $file fin
alias -g with='foreach'
alias -g run=';'
alias -g fin='; end'

# i/o
alias -g puts='print'
alias -g putf='printf'

function readin() {
  # get user input, with options
}
# write file.txt "ls"
function write() {
  local file="$1"
  shift
  eval "$@" >| "$file"
}
# append file.txt "print file stuff"
function append() {
  local file="$1"
  shift
  eval "$@" >> "$file"
}
# use block to load vars and functions into an environment
# eg:
# block example {
#   let value=12;
# }
alias block='function'
alias -g const='readonly'
alias -g let='local'
# atom, single item of data. a number or word
# useage: atom name "value"
function atom { 
  unsetopt warncreateglobal
  print $2 | read $1
}
# formatted ranges
range() { print {$1..$2}; }
range.nl() { range $1 $2 | tr ' ' '\n'; }
range.rev() { range.newline $1 $2 | sort -r; }
## a very simple data structure --------------------------
pair() { print "${1};${2}"; }
pair.delim() { print "${1}""${3}""${2}"; }
pair.cons() { print "${1:-$(cat -)}" | awk -F";" '{print $1}'; }
pair.cdr() { print "${1:-$(cat -)}" | awk -F";" '{print $2}'; }

##########################################################################
green "dsl loaded"