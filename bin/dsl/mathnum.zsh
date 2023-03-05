# DSL MATHNUM
calc() { print "$@" | bc; }

# math -------------------------------------------
add() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left + right))"; 
}
sub() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left - right))"; 
}
mul() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left * right))"; 
}
div() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left / right))"; 
}
pow() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left ** right))"; 
}
mod() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left % right))"; 
}
eq() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left == right))"; 
}
ne() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left != right))"; 
}
gt() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left > right))"; 
}
lt() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left < right))"; 
}
ge() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left >= right))"; 
}
le() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left <= right))"; 
}
incr ++() { local opt="${1:-$(cat -)}"; print $((++opt)); }
decr --() { local opt="${1:-$(cat -)}"; print $((--opt)); }
sum() { 
  print "${@:-$(cat -)}" | 
      awk '{for(i=1; i<=NF; i++) sum+=$i; } END {print sum}' 
}
## a number "object"
@num() {
  unsetopt warn_create_global
  local name="${1}"
  local value=${2}
  declare -rg $name=$value
  functions[$name]="print ${value}"  
  eval "
function $name { print ${value}; }
alias -g $name="$name"
"
  function _n() {
    val="$1"
    function "$name".add() { local opt=$1; add "$val" "$opt" }
    function "$name".sub() { local opt=$1; sub "$val" "$opt" }
    function "$name".mul() { local opt=$1; mul "$val" "$opt" }
    function "$name".div() { local opt=$1; div "$val" "$opt" }
    function "$name".pow() { local opt=$1; pow "$val" "$opt" }
    function "$name".mod() { local opt=$1; mod "$val" "$opt" }
    function "$name".eq() { local opt=$1; eq "$val" "$opt" }
    function "$name".ne() { local opt=$1; ne "$val" "$opt" }
    function "$name".gt() { local opt=$1; gt "$val" "$opt" }
    function "$name".lt() { local opt=$1; lt "$val" "$opt" }
    function "$name".ge() { local opt=$1; ge "$val" "$opt" }
    function "$name".le() { local opt=$1; le "$val" "$opt" }
    function "$name".incr() { incr $val }
    function "$name".decr() { decr $val }
    function "$name".sum() { local args="$@"; sum "$args" }
  }
  _n "$value"
}
functions["@num"]="@num"  
alias -g @num="@num"

##########################################################################
green "dsl/mathnum loaded"