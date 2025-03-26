function func() {
  #      1    2   3   4  @
  # func name arg arg -> body
  local name="$1"
  local a="$2"
  local b="$3"
  repeat 3; do shift; done
  local body="$@"
  eval "function $name { $1=$a; $2=$b; $body; }"
  #declare -rg "$name"="$name"
  #functions["$name"]="$name"
  #alias -g "$name"="$name"
}
