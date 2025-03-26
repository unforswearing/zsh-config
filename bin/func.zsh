# shellcheck shell=bash
environ "stdlib"
# -------------------------------------------------
# some methods for functions
function isfn() {
  libutil:argtest "$1"
  local char=" "
  local result
  result=$(
    type -w "$1" | awk -F: '{print $2}' | sed "s%^[${char//%/\\%}]*%%"
  )
  if [[ -z "$result" ]]; then
    false
  elif [[ $result == "function" ]]; then
    true
  else
    false
  fi
}
function fnbody() {
  libutil:argtest "$1"
  function getfn.body() {
    declare -f "$1" | sed '1d;$d'
  }
  getfn.body "$1"
}
# atom, single item of data. a number or word
# the concept of atoms are taken from elixir
#   - a constant whose value is its name
# eg atom hello => hello=hello
# useage: atom value
function atom() {
  libutil:argtest "$1"
  local nameval="$1"
  eval "function $nameval() print $nameval;"
  # if $1 is a number, don't use declare
  declare -rg "$nameval=$nameval" >|/dev/null 2>&1
  # shellcheck disable=2034
  functions["$nameval"]="$nameval" >|/dev/null 2>&1
  # atoms["$nameval"]="$nameval" >|/dev/null 2>&1
  # stdtypes["$name"]="atom"
}
# call a function with args
# return a function that outputs the result
# usage: memo <name> <function> <args...>
#    eg: memo stuffresult filestuff "file1.txt" "file2.txt"
function memo() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  local memoname="$1"
  local funcname="$2"
  shift; shift;
  local result=
  result=$($funcname "$@")
  eval "function ${memoname}() { 
    printf \"%s\n\" $result
  }"
}