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
  print "$(pair.cons "$1")
$(pair.cdr "$1")"
}
pair.torange() {
  range $(pair.cons "$1") $(pair.cdr "$1")
}
pair.toatom() {
  atom $(pair.cons "$1") $(pair.cdr "$1")
}
pair.toarr() {
  local name="$1"
  local cons=$(pair.cons "$2") 
  local cdr=$(pair.cdr "$2")
  arr "$name" ($cons $cdr)
}
<<<<<<< HEAD
# arrays will split into their indexes when used as arg
arr.topair() {
  pair $1 $2
}
=======
## ---------------------------------------------
green "dsl/pairs loaded"
>>>>>>> 1c0844edf3ab388200b9e7f59718b810b183f66a
