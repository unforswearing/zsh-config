# shellcheck shell=bash
# shellcheck disable=2034
gc() {
  {
    unhash "$1"
    unhash -d "$1"
    unhash -f "$1"
    unalias "$1"
    unset "$1"
    unset -f "$1"
    disable "$1"
    disable -r "$1"
    functions["$1"]=
    parameters["$1"]=
  } >/dev/null 2>&1
}
