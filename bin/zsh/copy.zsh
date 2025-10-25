#!/usr/local/bin/zsh
function copy() {
  test -z "$1" && {
    echo "copy <file|variable|text>"
    return
  }
  test -f "$1" && {
    cat "$1" | pbcopy
    echo "copied file: $1"
    return
  }
  # check if arg is a variable (testing parameter expansion)
  test -n "${(P)1}" && {
    echo "${(P)1}" | pbcopy
    echo "copied variable: $1"
    return
  }
  # fall through case - argument is probably a string
  echo "$1" | pbcopy
}