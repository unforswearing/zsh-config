#/usr/bin/env -i zsh --norcs
declare -A strs
function {var,pavs,preexec_alt_var_syntax}() {
  ## var varname : type -> value
  local current=$1
  source "/Users/unforswearing/zsh-config/usr/color.zsh"
  function libutil:argtest() {
    # usage libutil:argtest num
    # libutil:argtest 2 => if $1 or $2 is not present, print message
    setopt errreturn
    local caller=$funcstack[2]
    if [[ -z "$1" ]]; then
      color red "$caller: argument missing"
      return 1
    fi
  }  
  function trim() {
    local opt="${1:-$(cat -)}"
    libutil:argtest "$opt"
    print $opt | sd "(^\s+|\s+$)" ""
  }

  local name
  local value
  local vtype
  local composed

  if [[ $current =~ ' : (str(ing)?|num(ber)?) ->'  ]] && {
  # if [[ $current ]] && {
    # for item in ${=current}; do echo -en "$item\n"; done; 
    # current_array=(${=current})
    # current=(${=current[1]})
    current_array=(${=current})
    # print $current
    # print $@
    # print
    # print $current_array
    # current_array=${current_array[4,-1]}
    # print ${current_array[5]}
    # echo $current_array
    name=${current_array[1]}
    vtype=${current_array[3]}

    # value=${current_array[5]}
    # get all values after and including the fifth element
    # value=${current_array[4,-1]}
    # repeat 4; do shift current_array; done
    current_array=${current_array[5,-1]}
    value=${current_array}
    
    declare -rg $name=$value
    eval "function $name() { print $value; }"
    eval "functions $name.type() { print $vtype; }"

    strs["$name"]=true
  }
}
preexec_functions+=(var)
