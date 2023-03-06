# DSL MATHNUM
# math -------------------------------------------
math.add() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left + right))"; 
}
math.sub() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left - right))"; 
}
math.mul() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left * right))"; 
}
math.div() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left / right))"; 
}
math.pow() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left ** right))"; 
}
math.mod() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}"; 
  print "$((left % right))"; 
}
math.eq() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left == right))"; 
}
math.ne() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left != right))"; 
}
math.gt() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left > right))"; 
}
math.lt() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left < right))"; 
}
math.ge() { 
  local left="${1}"; 
  local right="${2:-$(cat -)}";  
  return "$((left >= right))"; 
}
math.le() { 
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
    function "$name".add() { local opt=$1; math.add "$val" "$opt" }
    function "$name".sub() { local opt=$1; math.sub "$val" "$opt" }
    function "$name".mul() { local opt=$1; math.mul "$val" "$opt" }
    function "$name".div() { local opt=$1; math.div "$val" "$opt" }
    function "$name".pow() { local opt=$1; math.pow "$val" "$opt" }
    function "$name".mod() { local opt=$1; math.mod "$val" "$opt" }
    function "$name".eq() { local opt=$1; math.eq "$val" "$opt" }
    function "$name".ne() { local opt=$1; math.ne "$val" "$opt" }
    function "$name".gt() { local opt=$1; math.gt "$val" "$opt" }
    function "$name".lt() { local opt=$1; math.lt "$val" "$opt" }
    function "$name".ge() { local opt=$1; math.ge "$val" "$opt" }
    function "$name".le() { local opt=$1; math.le "$val" "$opt" }
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