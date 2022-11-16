list() {
  local opt="${1}"
  local arg="${2}"
  local lst="$3"

  function run {
    python -c "$@"
  }
  
  case "${opt}" in
  "?") eval "echo \$$arg" ;;
  "index")
    # eg: list index idx $listvar
    run python "tmp = $lst; print(tmp[$arg])"
    ;;
  "length")
    # get list length
    lst=$arg
    run python "print(len($lst))"
    ;;
  "push")
    # put allows adding a single item to the list
    run python "tmp = $lst; tmp.append($arg); print(tmp)"
    ;;
  "rm_index")
    # remove item at index
    run python "tmp = $lst; tmp.pop($arg); print(tmp)"
    ;;
  "to_string")
    # output a space delimited list for looping
    run python "tmp = $lst; print(' '.join(tmp))"
    ;;
  *)
    # a list is just a function that returns its arguments as output
    # lists can be all strings (incl. func names) or numbers. no mixing types in lists
    local members="$@"
    local test_item="$1"
    local sepmembers
    [[ "${test_item}" =~ $POSIX_WORD ]] && {
      sepmembers="\"${members// /\", \"}\""
    } || {
      sepmembers="${members// /, }"
    }
    run python "tmp = [${sepmembers}]; print(tmp)"
    ;;
  esac
}
