##
# as function 'math_extension'
# https://www.nushell.sh/book/commands/math_abs.html
# https://www.nushell.sh/book/commands/math_avg.html
# https://www.nushell.sh/book/commands/math_ceil.html
# https://www.nushell.sh/book/commands/math_eval.html
# https://www.nushell.sh/book/commands/math_floor.html
# https://www.nushell.sh/book/commands/math_max.html
# https://www.nushell.sh/book/commands/math_median.html
# https://www.nushell.sh/book/commands/math_min.html
# https://www.nushell.sh/book/commands/math_mode.html
# https://www.nushell.sh/book/commands/math_product.html
# https://www.nushell.sh/book/commands/math_round.html
# https://www.nushell.sh/book/commands/math_sqrt.html
# https://www.nushell.sh/book/commands/math_stddev.html
# https://www.nushell.sh/book/commands/math_variance.html
#
## a "num" object
@num() {
  unsetopt warn_create_global
  local name="${1}"
  local value=${2}
  declare -rg $name=$value
  functions[$name]="echo ${value}"  
  eval "
function $name { echo ${value}; }
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

#################
# random.int 1..20
random.int() { nu -c "random integer $1"; }
# https://www.nushell.sh/book/commands/random_bool.html
# random.bool --bias 0.75
random.bool() { nu -c "random bool $1 $2"; }
# https://www.nushell.sh/book/commands/into_int.html
# echo "44" | toint
toint() { nu -c "\"${@:-$(cat -)}\" | into int"; }
# https://www.nushell.sh/book/commands/into_bool.html
# echo 4 | tobool
tobool() { nu -c "\"${@:-$(cat -)}\" | into bool"; }
# #####
# increment / decrement -------------------------------------------
incr ++() { local opt="${1:-$(cat -)}"; echo $((++opt)); }
decr --() { local opt="${1:-$(cat -)}"; echo $((--opt)); }
# math -------------------------------------------
add() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    echo "$((left + right))"; 
}
sub() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    echo "$((left - right))"; 
}
mul() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    echo "$((left * right))"; 
}
div() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    echo "$((left / right))"; 
}
pow() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    echo "$((left ** right))"; 
}
mod() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}"; 
    echo "$((left % right))"; 
}
eq() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    echo "$((left == right))"; 
}
ne() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    echo "$((left != right))"; 
}
gt() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    echo "$((left > right))"; 
}
lt() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    echo "$((left < right))"; 
}
ge() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    echo "$((left >= right))"; 
}
le() { 
    local left="${1}"; 
    local right="${2:-$(cat -)}";  
    echo "$((left <= right))"; 
}
sum() { 
    echo "${@:-$(cat -)}" | 
        awk '{for(i=1; i<=NF; i++) sum+=$i; } END {print sum}' 
}
count.lines() { wc -l | trim }
count.words() { wc -w | trim }
count.chars() { wc -m | trim }









