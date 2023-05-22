# shellcheck shell=bash
## pseudo objects: string and number
## TBD: obj:file, obj:dir
function obj:file() {
  :
  # read, write, append, created, modified, path, copy, rm, close
}
function obj:dir() {
  :
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
