# shellcheck shell=bash
environ "stdlib"
## a very simple data structure --------------------------
pair() {
  print "${1};${2}"
}
pair.cons() {
  print "${1:-$(cat -)}" | awk -F";" '{print $1}'
}
pair.cdr() {
  print "${1:-$(cat -)}" | awk -F";" '{print $2}'
}
pair.setcons() {
  print "$1" | sed 's/^.*;/'"$2"';/'
}
pair.setcdr() {
  print "$1" | sed 's/;.*$/;'"$2"'/'
}
# change ; to \n so pair can be used with loops
pair.iter() {
  :
}
pair.torange() {
  range "$(pair.cons "$1")" "$(pair.cdr "$1")"
}
pair.torange.reverse() {
  range "$(pair.cdr "$1")" "$(pair.cons "$1")"
}
pair.tovar() {
  atom "$(pair.cons "$1")" "$(pair.cdr "$1")"
}
## ---------------------------------------------
green "dsl/pairs loaded"
