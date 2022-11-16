tostr() { nu -c "\"${@:-$(cat -)}\" | into string"; }

@str() {
  unsetopt warn_create_global
  local name="${1}" && shift
  local value="\"${@}\""
  eval "
"$name"="${value}";
function "$name" { echo "${value}"; }
function $name.upper() { echo ${value} | upper ; }
function $name.lower() { echo ${value} | lower ; }
function $name.trim() { echo ${value} | trim ; }
function $name.trim.left() { echo ${value} | trim.left ; }
function $name.trim.right() { echo ${value} | trim.right ; }
function $name.len() { echo ${value} | len ; }
"
  _n() {
    val="${1}"
    funtion "$name".squeeze() { 
      local opt=$1; echo ${val} | squeeze "$val" "$opt"
    }
    funtion "$name".detox() { 
      local opt=$1; echo ${val} | detox "$val" "$opt"
    }
    funtion "$name".camel() { 
      local opt=$1; echo ${val} | trim | camel "$val" "$opt"
    }
    funtion "$name".snake() { 
      local opt=$1; echo ${val} | trim | snake "$val" "$opt"
    }
    funtion "$name".extract() { 
      local opt=$1; 
      local delim="$2"
      echo ${val//\"/} | awk -F"$delim" '{print $'$opt'}' 
    }
    funtion "$name".replace() { 
      local opt=$1; 
      local repl="$2"
      echo ${val//\"/} | replace "$opt" "$repl"
    }
  }
  _n "${value}"
}
contains() { nu -c "echo $(cat -) | str contains $@"; }
lpad() { nu -c "echo $(cat -) | str lpad --length=$1 --character=$2"; }
rpad() { nu -c "echo $(cat -) | str rpad --length=$1 --character=$2"; }
reverse() { nu -c "echo $(cat -) | str reverse $@"; }
substr() { nu -c "echo $(cat -) | str substring $@"; } 
# https://www.nushell.sh/book/commands/into_string.html
lower() { tr '[:upper:]' '[:lower:]'; }
upper() { tr '[:lower:]' '[:upper:]'; }
squeeze() {
  local char=${1:-[[:space:]]}
  sed "s%\(${char//%/\\%}\)\+%\1%g" | trim "$char"
}
squeeze.lines() {
  sed '/^[[:space:]]\+$/s/.*//g' | cat -s | trim.lines
}
detox() {
  sed 's/[^A-Za-z0-9 ]/ /g' |
    squeeze | sed 's/ /_/g' | lower
}
title() {
  lower | sed 's/\<./\u&/g' |
    sed "s/'[[:upper:]]/\L&\l/g"
}
camel() {
  sed 's/_/ /g' |
    sed 's/\<\(.\)/\U\1/g' |
    sed 's/ //g'
}
snake() {
  sed 's/\([[:upper:]]\)/ \1/g' | detox
}
trim() { trim.left | trim.right; }
trim.left() {
  local char=${1:-[:space:]}
  sed "s%^[${char//%/\\%}]*%%"
}
trim.right() {
  local char=${1:-[:space:]}
  sed "s%[${char//%/\\%}]*$%%"
}
trim.lines() {
  sed ':a;$!{N;ba;};s/^[[:space:]]*\n//;s/\n[[:space:]]*$//'
}
# get item(s) from a particular column
# extract $column $delimeter
extract() { awk -F"$2" '{print $'"$1"'}' | trim; }
# a simple replace command
replace() { sd "$1" "${2:-$(cat -)}"; }
# synonym for {$start..$end} ----------------------
range() { echo {$1..$2}; }
range.newline() { range $1 $2 | tr ' ' '\n'; }
range.reverse() { range.newline $1 $2 | sort -r; }
# https://www.nushell.sh/book/commands/random_chars.html
random.char() { nu -c "random chars --length ${1:-26}"; }
# # strings and arrays can use len ----------------
len() {
  local item="${1:-$(cat -)}"
  echo "${#item}"
}
idx() {
  local opt="$1"
  shift 
  gexpr index "${opt:-$(cat -)}" "${1}"
}
str.exists() { ; } # -n





