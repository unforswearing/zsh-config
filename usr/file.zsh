# shellcheck shell=bash
environ "stdlib"
function file() {
  libutil:argtest "$1"
  # bkp filename.txt => filename.txt.bak
  # restore filename.txt => overwrites filename.txt
  function file.bkp() {
    /bin/cp "${1}"{,.bak}
  }
  function file.exists() {
    # shellcheck disable=2317
    if [[ -s "${1}" ]]; then true; else false; fi
  }
  function file.copy() {
    # shellcheck disable=2189
    <"${1}" | pbcopy
  }
  function file.read() {
    print "$(<"${1}")"
  }
  function file.rest() {
    /bin/cp "${1}"{.bak,} && rm "${1}.bak"
  }
  function file.empty() {
    if [[ -e "${1}" ]] && [[ ! -s "${1}" ]]; then
      true
    else
      false
    fi
  }
  function file.isnewer() {
    libutil:argtest "$1"
    libutil:argtest "$2"
    if [[ "${1}" -nt "${2}" ]]; then true; else false; fi
  }
  function file.isolder() {
    libutil:argtest "$1"
    libutil:argtest "$2"
    if [[ "${1}" -ot "${2}" ]]; then true; else false; fi
  }
  local opt="$1"
  shift
  case "$opt" in
  backup) file.bkp "$@" ;;
  copy) file.copy "$@" ;;
  read) file.read "$@" ;;
  restore) file.rest "$@" ;;
  isempty) file.empty "$0" ;;
  isolder) file.isolder "$@" ;;
  isnewer) file.isnewer "$@" ;;
  *) libutil:error.option "$opt" ;;
  esac
}