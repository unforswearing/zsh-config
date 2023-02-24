tostr() { nu -c "\"${@:-$(cat -)}\" | into string"; }
printstr() { echo -en "$@";  }
###
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
quote() {
  test ${#[@]} -gt 1 && {
    printf '"%s" ' "$@"
  } || {
    printf '"%s"' "$1"  
  }
  print "\n" 
}



