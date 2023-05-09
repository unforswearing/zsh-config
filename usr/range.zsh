# formatted ranges
# do not quote - range can be alpha or num
#  - maybe: range int $1 $2 / range str "$1" "$2"
# todo: incorporate seq and / or jot to do more stuff
# also: https://linuxize.com/post/bash-sequence-expression/
range() { 
  local incrementor="..${3:-1}"
  print {$1..$2$incrementor}
}
# a range of integers
range.int() {;}
# a range of letters
range.str() {;}
# range.wrap "a" 4 5 "zz" => a4zz a5zz
range.wrap() {;}
range.nl() { 
  local incrementor="..${3:-1}"
  print {$1..$2$incrementor} | tr ' ' '\n'
}
range.rev() { 
  local incrementor="..${3:-1}"
  print {$1..$2$incrementor} | tr ' ' '\n' | sort -r
}