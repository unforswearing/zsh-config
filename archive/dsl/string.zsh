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
## ---------------------------------------------
green "dsl/string loaded"