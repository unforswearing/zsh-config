# shellcheck shell=bash
# #################################################
# this exists seperately / alongside stdlib.zsh
# neither file relies on the other and can be used independently
# -----------------------------------------
# pseduo types: a way to create types in zsh, retaining zsh-isms
# - everything is text unless casted otherwise
# - all casted items have the list as a primary type
# - this means strings are lists of chars, floats are lists of numbers
#   and functions are lists of commands
# - all of these items can be treated like a list where necessary
# -----------------------------------------
# (pseudo types - type signatures)
# (type signatures are used to declare types, not check)
# type       in zsh
# ----------------------------
# nil - cat /dev/null
# bool  - true false
# number - never quoted. /[0-9]{1}/
# char - always quoted. /[aA-zZ]|[0-9]|\s|\t|[:punct:]{1}/
# list - typeset -a name=("this" "is" "a" "list")
# str - strings are lists of chars
#      | eg: string name="robert smith"
# float - floats are lists of one or more numbers, using half precision 
# fun - functions are lists of commands
#      | the 'fun' type creates the signature for a function
#      | eg: fun getage (str $1) -> num
#      |     getage() { `$name match "robert smith"` && print $age; }
# note: ---
#      | str and num output is an immutable function that returns the value
#      | output functions all have a param called 'type'
#      | eg. str hello="world"; hello type => str
# --------------------------------------------------
# see also:
# - value-level programming: https://en.wikipedia.org/wiki/Value-level_programming
# - static typing: https://en.wikipedia.org/wiki/Type_system#Static_type_checking
# - nominal type system: https://en.wikipedia.org/wiki/Nominal_type_system
# - the abstract type: https://en.wikipedia.org/wiki/Abstract_type
# - types produce immutable values
# - no type constructor
# - no type coersion
# - no aliases

# #################################################
# @todo revise how these work (numbers should use `float`, etc)
# @todo develop an internal way to track references to the types
# @todo once internal type method is derived, create funcs to get and convert types
# @todo use a python with the `typing` and `mypy` modules
# 
# pseudo types were pulled from stdlib. 
# create pseudo types: nil, num, const, atom
#
# instead of Lua for types, use Python. Including:
#
# - typing: https://docs.python.org/3/library/typing.html
# - mypy: https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html#cheat-sheet-py3
#
# with these I do not have to use some weird / outdated / incompatible typed lua dialect like teal (cool, but requires type files and examples are non-existent), or luau (incompatible with MacOS < 10.12), or Terra (systems programming library that calls itself a language built onto Lua), and etc. 
# #################################################
#
# ------ use zsh-based variable declaration ------
# (these do not set a type, only modify access for vars)
# set        init variables outside of functions: `set name`
# local      init variables inside of functions: `local name`
# readonly   constants: `readonly name="mike"`
# export     globals: `export fullname="$name thomas"`
# -------------------------------------------------
#
# note: the method of checking types (using `isstr` for example) 
# may not be necessary since any item using a type signature 
# will have the type added to the resulting function as a parameter. 
# for example `nil result; result type` => prints 'nil'
#
# #################################################
# 
# use the functions below to define what each type is
# for later comparison. not all functions will be type signatures
# ------------------------
function ptype:util.varname() {
  print "${1}" | awk -F= '{print $1}'
}
function ptype:util.varvalue() {
  print "${1}" | awk -F= '{print $2}'
}
# -------------------------------------------------
# type checking funcs
function isnil() {
  local item="$1"
  local devnull=
  devnull=$(cat /dev/null)
  if [[ $item == "$devnull" ]]; then
       return 0
  else
    return 1
  fi 
}

function isbool() {
  local item="$1"
  case "$1" in
    true) return 0 ;;
    false) return 0 ;;
    0) return 0 ;;
    1) return 0 ;;
  esac
  return 1
}
# function isnum() {
#   local ck=${1#[+-]}
#   ck=${ck/.}
#   if [ "$ck" ] && [ -z "${ck//[0-9]}" ]; then
#     return 0
#   else
#     return 1
#   fi
# }
function isnum() {
  # shellcheck disable=2089
  local luaint='
local is_int = function(n)
  return (type(n) == "number") and ((math.floor(n) == n) or (math.type(n) == "float"))
end
print(is_int('"$1"'))
'
  lua <(print "$luaint")
}
function char() {
  :
}
function list() {
  local item="$1"
  # shellcheck disable=2296
  local islist=${(t)item}
  print $islist
  if [[ $islist =~ "array" ]]; then
    return 0
  else 
    return 1
  fi
}
# -------------------------------------------------
# type signatures
function nil() {
  # nil can be used to return false by using it 
  # without an argument to trigger the argtest `return 1`
  # a nil type
  # use `cmd discard` for sending commands to nothingness
  local name="$1"
  local value=
  value=$(cat /dev/null)
  declare -rg "$name=$value"
  eval "function $name() {
    case \$1 in
      type) print \"nil\" ;;
      *) print $value ;;
    esac
  }"
}
function str() {
  # str max length < 16bit float max
  # strings terminate on newline
  # method for multi line strings

  # the following is maybe:
  # more than one string is a list (internal)
  # if str > float max split string to list
  # strings are represented internally as hex
  # convert a char to hex
  echo -n "Z" | xxd -p # => 5a
  # convert a string to hex
  # produces \x\x\x\x\x\x\x\x\x\x\x66\x\x61\x\x72\x\x74\x\x20\x\x74\x\x69\x\x6d\x\x65\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x\x
  echo -n "fart time" | od -An -tx1 | sed 's/ /\\x/g'
  # convert a char back from hex
  echo $'\x5a' # => Z
  # convert hex back to string (not perfect in zsh)
   echo $'"'$(print $longhex)'"'
}
export FLOAT_PRECISION=10
function _float() { 
  # use half precision 16 bit
  # https://observablehq.com/@rreusser/half-precision-floating-point-visualized
  # float -F min=$(insect "-1 * 2^15 * (1 + (1023/1024))") => -65504
  # float -F zero=$(insect "1 * 2^-14 * (1 + (0/1024))") => 0.0000610352
  # float -F max=$(insect "1 *(2^15) * (1 + (1023/1024))") => 65504
  # float -F infinity=$(insect "1 * 2^16 * (1 + (0/1024))") => +/-65536
  # float -F nan=$(insect "-1 * 2^16 * (1 + (1/1024))") => +/-65600
  # note: higher than inifinity is nan
  # note: nan is also non-numeric characters
  float -F "$FLOAT_PRECISION" "${1}"
  local name; local value;
  name=$(ptype:util.varname "$1")
  value=$(ptype:util.varname "$2")
  declare -rg "$name=$value" >|/dev/null 2>&1
  # shellcheck disable=2034
  functions["$name"]="$value" >|/dev/null 2>&1
  # ints["$name"]="$value" >|/dev/null 2>&1
  # stdtypes["$name"]="int"
  eval "function $name() {
    case \$1 in
      type) print \"float\" ;;
      *) print $value ;;
    esac
  }"
}
# fun name <arg type...> -> <return type>
# fun getage :str -> :num
function fun() {
  local name="$1"
  shift 
  # the args array should be compared to this array of 
  # types, error if arg totals dont match or if args 
  # are not of the specified type
  local args=$(print "$name" | awk -F"->" '{print $1}')
  local ret=$(print "$name" | awk -F"->" '{print $2}')
  
}
# -------------------------------------------------
# typecheck a file
typecheck() {
  local caller=${funcstack[2]}
}
