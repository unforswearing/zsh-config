function list() {
  # note:
  #  for complicated stuff, switch to python,
  #  it will be easier than trying to use awk / arrays
  # ```bash
  # function py_array() {
  #   # $1 = "['this is a value', 2, True, 5.5, 'end']"
  #   python3.11 -c "
  # import ast
  # array = str(\"$1\")
  # print(ast.literal_eval(array))
  # "
  # }
  # ---
  # libutil:argtest "$1"
  # list name "'item', 1, 5, true"
  # list print | get | foreach | pop | push | shift | reverse | filter
  #
  # Note:
  # make it so that list names are functions so i can do things like
  # ```
  # list data_items = "data1, data2, data3"
  # data_items foreach item "function() { print $item; }"
  #
  # # or
  #
  # list foreach item $data_items "function() { print $item; }"
  # ```
  _.util.isstr() {
    # unsetopt warncreateglobal
    # libutil:argtest "$1"
    local testval="$1"
    [[ $testval =~ [^0-9] ]]
  }
  _.util.quote() {
    # libutil:argtest "$1"
    local input="$1"
    printf "%s" "$input" | sd "(^|$)" "\""
  }
  _.util.makeiter() {
    local item="${1}"
    <<<"$item" | sd "," ""
  }
  list.print() {
    local _list="${1}"
    <<<"{ ${_list} }"
  }
  # list.get can only work if each item in the list is one string with no spaces
  # quoting doesn't work, will have to use a different programming language
  # to get around this issue (python is planned)
  list.get() {
    local _list="${1}"
    declare -a _as_array=($_list)
    local _index="${2}"
    print "${_as_array[$_index]}"
  }
  list.pop() {
    local _list=$(_.util.makeiter "${1}")
    declare -a _as_array=($_list)
    local _length="${#_as_array}"
    <<<"${_list}" | awk '{print $'"$_length"'}'
  }
  # list several_items "item1, item2, item3"
  # list push $several_items "newitem" -> "item1, item2, item3, newitem"
  # list all_items $(list push $several_items "newitem")
  list.push() {
    local _list=$(_.util.makeiter "${1}")
    #declare -a _as_array=($_list)
    local _newitem="${2}"
    [[ $_newitem =~ [^0-9] ]] && \
      _newitem="$(_.util.quote "${_newitem}")"
    #_as_array+=("$_newitem")
    #print "${_as_array[@]}"
    printf "%s %s\n" "${_list}" "${_newitem}"
  }
  list.shift() {
    :
  }
  list.reverse() {
    :
  }
  list.foreach() {
    :
  }
  list.filter() {
    :
  }
  list.contains() {
    :
  }
  local arg="${1}"
  local opt="${2}"
  local idx="${3}"
  case "${arg}" in
    print) list.print "${opt}" ;;
    get) list.get "${opt}" "${idx}" ;;
    foreach) ;;
    pop) list.pop "${opt}" "${item}" ;;
    push) item="${idx}"; list.push "${opt}" "${item}" ;;
    shift) ;;
    reverse) ;;
    filter) ;;
    contains) ;;
    *) eval "${arg}=${opt}"
    ;;
  esac
}