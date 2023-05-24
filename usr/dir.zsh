# shellcheck shell=bash
environ "stdlib"
# directory actions
function dir() {
  libutil:argtest "$1"
  function dir.new() {
    # shellcheck disable=2164
    ccd() { mkdir -p "$1" && cd "$1"; }
    # mkdir "$@";
    case "$1" in
    "cd")
      shift
      ccd "$1"
      ;;
    *)
      libutil:argtest "$@"
      mkdir "$@"
      ;;
    esac
  }
  function dir.bkp() {
    cp -r "${1}" "${1}.bak"
  }
  function dir.rst() {
    cp -r "${1}.bak" "${1}" && rm -rf "${1}.bak"
  }
  function dir.parent() { dirname "${1}"; }
  function dir.up() {
    libutil:argtest "$1"
    case "${1}" in
    "") cd .. || return ;;
    *) cd "$(eval "printf -- '../'%.0s {1..$1}")" || return ;;
    esac
  }
  function dir.isnewer() {
    if [[ "${1}" -nt "${2}" ]]; then true; else false; fi
  }
  function dir.isolder() {
    if [[ "${1}" -ot "${2}" ]]; then true; else false; fi
  }
  local opt="$1"
  shift
  case "$opt" in
  new) dir.new "$@" ;;
  backup) dir.bkp "$@" ;;
  restore) dir.rst "$@" ;;
  parent) dir.parent "$@" ;;
  # previous) ;;
  up) dir.up "$@" ;;
  isolder) dir.isolder "$@" ;;
  isnewer) dir.isnewer "$@" ;;
  *) libutil:error.option "$opt" ;;
  esac
}
