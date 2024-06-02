# DSL STRING
## ---------------------------------------------
function lower() {
  libutil:argtest "$1"
  local opt="${1}"
  print "$opt" | tr '[:upper:]' '[:lower:]'
}
function upper() {
  libutil:argtest "$1"
  local opt="${1}"
  print "$opt" | tr '[:lower:]' '[:upper:]'
}
ltrim() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print $opt | sd "^\s+" ""
}
rtrim() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print $opt | sd "\s+$" ""
}
function trim() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print "$opt" | sd "(^\s+|\s+$)" ""
}
function length() {
   libutil:argtest "$1"
   local arg="${1}"
   print "${#arg}"
}
function toiter() {
  # split a string by char into newlines for iterating over
   libutil:argtest "$1"
   local arg="${1}"
   print "$arg" | trim | sd "" "\n" | tail -n +2
}
function contains() {
  # using nushell
  libutil:argtest "$1"
  local str="${2:-$(cat -)}"
  local result=$(echo "$str" | grep -o "$1")
  if [[ $result == "true" ]]; then true; else false; fi
}
# a string matcher, since the `eq` function only works for numbers
# match will check the entire string. use contains for string parts
function match() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  local left="${1}"
  local right="${2}"
  if [[ "$left" == "$right" ]]; then true; else false; fi
}
# a simple replace command
function replace() {
  libutil:argtest "$1"
  libutil:argtest "$2"
  sd "${1}" "${2}"
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
## ---------------------------------------------
green "dsl/string loaded"