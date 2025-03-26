#!/bin/bash

function run_rg() {
  {
    rg --files --glob '!archive*' --glob '!plugin*' "$@";
    echo ":exit"
  }
}

while :; do
  selection="$(run_rg "$@"| fzf)";
  # selection="$(read)";
  if [[ "$selection" == ":exit" ]]; then
    return;
  fi;
  micro "$selection";
done
