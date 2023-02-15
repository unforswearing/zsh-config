#################
calc() { echo "$@" | bc; }
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
count.lines() { wc -l | trim; }
count.words() { wc -w | trim; }
count.chars() { wc -m | trim; }









