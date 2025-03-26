# shellcheck shell=bash
environ "stdlib"
## pseudo objects: string and number
## TBD: obj:file, obj:dir
# 5/23/2023: obj:file / @file does not work
function obj:file() {
  # open, read, write, append, created, modified, path, copy, close
  @file() {
    unsetopt warn_create_global
    local name="$1"
    local path="$2"
    f.read() { cat $1; }
    f.write() { local f="$1"; shift; print "$@" >| "$f"; }
    # shellcheck disable=1009,1072,1073
    f.append() { local f="$1"; shift; print "$@" >>| "$f"; }
    f.copy() { local f="$1"; shift; /bin/cp "$f" "$2"; }
    f.close() { import gc && gc "$1"; }
    function f.open() {
      # f.open "name" "/path/name.txt"
      local ofile="$1"
      local oname="$(basename $1)"
      local ocontents="$(f.read)"
      local opath="$2"
      local ocreated="$(gstat -c %w $1)"
      local omodified="$(gstat -c %y $1)"
      eval "
      function $1() {
        function $1.name() { print $oname; }
        function $1.contents() { print $ocontents; }
        function $1.path() { print $opath; }
        function $1.created() { print $ocreated; }
        function $1.modified() { print $omodified; }
      }
      "
      print "
        name: $oname
        contents: $ocontents
        path: $opath
        created: $ocreated
        modified: $omodified
      "
    }
    declare -rg $name=$path
    functions[$name]="$(f.open $1 $2)"
    function _n() {
      function $name.read() { f.read $1; }
      function $name.write { local opt=$1; shift; f.write $opt $@; }
      function $name.append() { local opt=$1; shift; f.append $opt $@; }
      function $name.copy() { local opt=$1; shift; f.copy $opt "$@"; }
      function $name.close() { f.close $path; }
    }
    _n "$value"
  }
  @file "$@"
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
