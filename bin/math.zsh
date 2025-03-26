# shellcheck shell=bash
environ "stdlib"
# math -------------------------------------------
# all math commands (AND ONLY MATH COMMANDS) can be used in two ways:
# add 2 2 => 4
# print 2 | add 2 => 4
function add() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left + right))"
}
function sub() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left - right))"
}
function mul() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left * right))"
}
function div() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left / right))"
}
function pow() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left ** right))"
}
function mod() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  print "$((left % right))"
}
function eq() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -eq "$right" ]]; then true; else false; fi
}
function ne() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -ne "$right" ]]; then true; else false; fi
}
function gt() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -gt "$right" ]]; then true; else false; fi
}
function lt() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -lt "$right" ]]; then true; else false; fi
}
function ge() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -ge "$right" ]]; then true; else false; fi
}
function le() {
  local left=
  local right="${2:-$1}"
  libutil:argtest "$right"
  if [[ "$right" -eq "$1" ]] && [[ -z "$2" ]]; then
    left="$(cat -)"
  else
    left="$1"
  fi
  libutil:argtest "$left"
  if [[ "$left" -le "$right" ]]; then true; else false; fi
}
function incr() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print $((++opt))
}
function decr() {
  local opt="${1:-$(cat -)}"
  libutil:argtest "$opt"
  print $((--opt))
}
function sum() {
  # shellcheck disable=2124
  local valueargs="${@:-$(cat -)}"
  libutil:argtest "$valueargs"
  print "${valueargs}" |
    awk '{for(i=1; i<=NF; i++) sum+=$i; } END {print sum}'
}
function calc() {
  libutil:argtest "$1"
  print "$@" | bc
}