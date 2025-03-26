#!/usr/bin/env -i zsh
# shellcheck shell=bash
# This file will mostly be used interactively, however it can
# work as a standalone library when sourced from other zsh scripts.
#
# `stdlib.zsh` can also be used with Lua / Teal to write shell scripts
#  by generating standalone files in the /src/bin directory for
#  use as a lua/zsh shared library
#    - See generate_binfiles() at the bottom of this file
#    - See zconf/src
#
# check if a file has access to stdlib.zsh by using `environ "stdlib"`
# at the top of the file. the command will fail at environ and when 
# checking for stdlib, if environ is somehow set and available. 
#
# @todo track metadata for better error messages, etc
#   for example, set up a system to track the names of required function args
#   eg: function import::meta.args() { print "1=filename"; }
#
# shellcheck source=/Users/unforswearing/zsh-config/bin/stdlib.zsh
export stdlib="/Users/unforswearing/zsh-config/bin/stdlib.zsh"
# ###############################################
function lib:color() { 
  local ZSH_BIN_DIR="/Users/unforswearing/zsh-config/bin"
  source "${ZSH_BIN_DIR}/color.zsh"
}
# ###############################################
function lib:env() {
  setopt bsd_echo
  setopt c_precedences  
  setopt cshjunkie_loops
  setopt function_argzero
  setopt ksh_option_print
  setopt ksh_zero_subscript
  setopt local_loops
  setopt no_append_create
  setopt no_clobber
  setopt sh_word_split
  setopt warn_create_global
  setopt warn_nested_var
}
# ###############################################
# error throwing / internals
# -----------------------------------------------
function libutil:reload() { source "${stdlib}"; }
function libutil:argtest() {
  # usage libutil:argtest num
  # libutil:argtest 2 => if $1 or $2 is not present, print message
  setopt errreturn
  # shellcheck disable=2154
  local caller=${funcstack[2]}
  if [[ -z "$1" ]]; then
    lib:color red "$caller: argument missing"
    return 1
  fi
}
function libutil:error.option() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  lib:color red "$caller: no method named '$fopt'" 
  return 1
}
function libutil:error.option() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  lib:color red "$caller: no method named '$fopt'" 
  return 1
}
function libutil:error.unsetvar() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  lib:color red "$caller: variable '$1' is not set in current environment"
  return 1
}
function libutil:error.notfound() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  lib:color red "$caller: '$1' not found in current environment" 
  return 1
}
function libutil:error.overwrite() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  lib:color red "$caller: file '$1' exists, will not overwrite" 
  return 1
}
function libutil:error.nofile() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  lib:color red "$caller: file '$1' does not exist" 
  return 1
}
function libutil:error.nodir() {
  libutil:argtest "$1"
  setopt errreturn
  local caller=${funcstack[2]}
  local fopt="$1"
  lib:color red "$caller: directory '$1' does not exist" 
  return 1
}
# ###############################################
# methods for checking for the existence of various things in the zsh env
# import, require, environ, file, dir
# -------------------------------------------------
# stdlib.zsh functions are available in imported files
# typeset -T env_imports="" stdlib_import ", "
function import() {
  local ZSH_BIN_DIR="/Users/unforswearing/zsh-config/bin"
  libutil:argtest "$1"
  case "$1" in
  "async") source "${ZSH_BIN_DIR}/async.zsh" ;;
  "await") source "${ZSH_BIN_DIR}/await.zsh" ;;
  "binfile") source "${ZSH_BIN_DIR}/binfiles.zsh" ;;
  "cleanup") source "${ZSH_BIN_DIR}/cleanup.zsh" ;;
  "color") source "${ZSH_BIN_DIR}/color.zsh" ;;
  "conv") source "${ZSH_BIN_DIR}/conversion.zsh" ;;
  "datetime") source "${ZSH_BIN_DIR}/datetime.bash" ;;
  "extract") source "${ZSH_BIN_DIR}/extract.bash" ;;
  "func") source "${ZSH_BIN_DIR}/func.bash" ;;
  "gc") source "${ZSH_BIN_DIR}/gc.zsh" ;;
  "help") source "${ZSH_BIN_DIR}/help.zsh" ;;
  "jobs") source "${ZSH_BIN_DIR}/jobs.zsh" ;;
  "lnks") source "${ZSH_BIN_DIR}/lnks.bash" ;;
  "math") source "${ZSH_BIN_DIR}/math.bash" ;;
  "net") source "${ZSH_BIN_DIR}/net.zsh" ;;
  "object") source "${ZSH_BIN_DIR}/object.zsh" ;;
  "repl") source "${ZSH_BIN_DIR}/replify.sh" ;;
  "string") source "${ZSH_BIN_DIR}/string.sh" ;;
  "update") source "${ZSH_BIN_DIR}/update.zsh" ;;
  "iterm")
    test -e "${HOME}/.iterm2_shell_integration.zsh" &&
      source "${HOME}/.iterm2_shell_integration.zsh"  
    ;;
  *) 
    libutil:error.option "''"
    ;;
  esac
  # stdlib_import+="$1"
}
function unload() {
  libutil:argtest "$1"
  unhash -f "$1" || libutil:error.option "$1"
}
# -------------------------------------------------
# require: ensure a command or builtin is available in the environment
# usage: require "gsed"
# typeset -T env_required="" stdlib_require ", "
function require() {
  libutil:argtest "$1"  
  local comm=
  comm="$(command -v $1)"
  if [[ $comm ]]; then 
    # stdlib_require+="$comm"  
    true
  else 
    libutil:error.notfound "$1" 
  fi
}
# environ: check for the existence of variables in the environment
# usage: environ "XDG_CONFIG_HOME"
# typeset -T env_environs="" stdlib_environ ", "
function environ() {
  libutil:argtest "$1"  
  local varname
  varname="$1"
  if [[ -v "$varname" ]] && [[ -n "$varname" ]]; then 
    # stdlib_environ+="$varname"
    true
  else 
    libutil:error.unsetvar "$1"
  fi
}
# -------------------------------------------------
# test if a file exists and is not empty
# usage: file "filename.txt"
function file() {
  libutil:argtest "$1"  
  local name="$1"
  if [[ -s "$name" ]]; then 
    true
  else 
    libutil:error.nofile "$name"
  fi
}
# test if a dir exists 
# usage: dir "/path/to/directory"
function dir() {
  libutil:argtest "$1"  
  local name="$1"
  if [[ -d "$name" ]]; then 
    true
  else
     libutil:error.nodir "$name" 
  fi
}
function option() {
  libutil:argtest "$1"
  # shellcheck disable=2154,2203
  if [[ ${options[$1]} == "on" ]]; then
    true
  else
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]]; then checkopt "$1"; fi
}
# ###############################################
# managing shell options
# -------------------------------------------------
# topt: toggle the option - if on, turn off. if off, turn on
function topt() {
  libutil:argtest "$1"
  # shellcheck disable=2154,2203
  if [[ ${options[$1]} == "on" ]]; then
    unsetopt "$1"
  else
    setopt "$1"
  fi
  if [[ "$2" != "quiet" ]]; then checkopt "$1"; fi
}
function checkopt() {
  libutil:argtest "$1"
  # https://unix.stackexchange.com/a/121892
  print "${options[$1]}"
}
# ###############################################
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
  *) libutil:error.option "$opt" ;;
  esac
}
function memory() { sysinfo memory; }
# ###############################################
if [[ $limit_stdlib == true ]]; then return 0; fi
# ###############################################
# begin stdlib.zsh interactive functions
# ###############################################
# import / require / environ things for this script
# -----------------------------------------------
import color
require "nu"
require "sd"
environ "options"
environ "functions"
# -------------------------------------------------
# test `isfn get`; and "print yes"; or "print no";
function and() {
  libutil:argtest "$@"
  # shellcheck disable=2181
  (($? == 0)) && eval "$@"
}
function or() {
  libutil:argtest "$@"
  # shellcheck disable=2181
  (($? == 0)) || eval "$@"
}
function cmd() {
  libutil:argtest "$1"
  function cmd.cpl() {
    require "pee"
    local OIFS="$IFS"
    IFS=$'\n\t'
    local comm;
    comm=$(history | tail -n 1 | awk '{first=$1; $1=""; print $0;}')
    echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"
    IFS="$OIFS"
  }
  # similar to cmd.devnull, but command is used as
  # an argument to the function.
  # usage: cmd discard "ls | wc -l"
  function cmd.discard() {
    eval "$@" >|/dev/null 2>&1
  }
  # similar to cmd.devnull, but command is used
  # in / at the end of a pipe, not as an argument.
  # usage: ls | wc -l | cmd devnull
  function cmd.devnull() {
    # for use with pipes
    true >|/dev/null # 2>&1
  }
  # cmd norcs "declare -f periodic"
  # the above will print nothing since periodic is set in zshrc
  # use cmd norcs to run command in an env with no zsh sourcefiles
  function cmd.norcs() { 
    env -i zsh --no-rcs -c "$@"; 
  }
  # run a command with options enabled
  # cmd withopt "warncreateglobal warnnestedvars" "<cmd>"
  function cmd.withopt() {
    local opt="$1"
    shift
    setopt "$opt"
    eval "$@"
  }
  function cmd.noopt() {
    local opt="$1"
    shift
    unsetopt "$opt"
    eval "$@"
  }
  function cmd.settimeout() {
    local opt="$1"
    shift
    (sleep "$opt" && eval "$@") &
  }
  function cmd.default() {
    local opt="$1"
    shift
    $(command -v "$opt") "$@"
  }
  local opt="$1"
  shift
  case "$opt" in
  last) cmd.cpl ;;
  discard) libutil:argtest "$@" && cmd.discard "$@" ;;
  devnull) cmd.devnull ;;
  norcs) cmd.norcs "$@" ;;
  withopt) cmd.withopt "$@" ;;
  noopt) cmd.noopt "$@" ;;
  timeout) cmd.settimeout "$@" ;;
  default) cmd.default "$@" ;;
  *) libutil:error.option "$opt" ;;
  esac
}
# -------------------------------------------------
# this get function is a limited version of bin/pseudotypes.zsh:get()
function get() {
  function getvar() {
    # dont use $ with var
    # getvar PATH
    # todo: hide output if there is no match
    local value
    value=$(eval "print \$${1}")
    if [[ -z "$value" ]]; then
      libutil:error.notfound "$1"
    else
      print "$value"
    fi
  }
  function getfn() {
    # todo: hide output if there is no match
    declare -f "$1"
  }
  function getfn.body() {
    declare -f "$1" | sed '1d;$d'
  }
  local opt="$1"
  shift
  case "$opt" in
  var) libutil:argtest "$1" && getvar "$1" ;;
  fn) libutil:argtest "$1" && getfn "$1" ;;
  fnbody) libutil:argtest "$1" && getfn.body "$1" ;;
  *) libutil:error.option "$opt" ;;
  esac
}
# -------------------------------------------------
function puts() { 
  local opt="$@"
  local txt="${opt:-""}"
  print "${txt}"; 
}
function putf() {
  libutil:argtest "$@"
  printf "%s\n" "$@"
}
function dump() {
  # dump file.txt
  libutil:argtest "$1"
  cat "${1}"
}
function write() {
  # write "text" file.txt
  # print hi | write file.txt
  # error if file exists and is not empty
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  if [[ -s "$opt" ]]; then
    libutil:error.overwrite "$opt"
  else 
    printf "%s\n" "$@" >|"$opt"
  fi
}
function append() {
  # append "text" file.txt
  # error if file does not exist
  libutil:argtest "$1"
  libutil:argtest "$2"
  local txt="${1}"
  local file="${2}"
  # error if file does not exist or is empty
  if [[ ! -s "$file" ]]; then
    libutil:error.nofile "${file}"
  else 
    shift
    # disabled shellcheck for zsh option `no_append_create`
    # shellcheck disable=1009,1072,1073
    printf "%s\n" "$txt" >>|"$file"
  fi
}
function prepend() {
  # prepend "text" file.txt
  # print hi | prepend file.txt
  libutil:argtest "$1"
  libutil:argtest "$2"
  local txt="${1}"
  local file="${2}"
  # error if file does not exist or is empty
  if [[ ! -s "$file" ]]; then
    libutil:error.nofile "$file"
  else 
    shift
    local contents="_prepend_${RANDOM}.txt"
    touch "${contents}"
    # disabled shellcheck for zsh option `no_append_create`
    # shellcheck disable=1009,1072,1073
    cat "$file" | sort -r | 
      { cat -; print "$txt"; } | sort -r >> "${contents}"
    /bin/mv "${contents}" "${file}"
  fi
}
function list() {
  # print dir contents
  # list /Users
  local opt="${1:-$(pwd)}"
  libutil:argtest "$opt"
  if [[ ! -d "$opt" ]]; then
    libutil:error.nodir "$opt"
  else 
    require "fd"
    fd --color never \
       --type file \
       --type directory \
       --hidden \
       --ignore-vcs \
       --exclude "*.git" \
       --max-depth 1 \
       --search-path "$opt"
  fi
}
# create a new dir that branches from the specified location
# `cd Documents && branch files/newstuff` creates a files/newstuff
# directory in the Documents folder
function branch() {
  libutil:argtest "$1"  
  local opt="$1"
  /bin/mkdir -p "$opt"
}
## ---------------------------------------------
# disable the use of some keywords by creating empty aliases
disable -r "integer" \
  "time" \
  "select" \
  "coproc" \
  "nocorrect" \
  "repeat"