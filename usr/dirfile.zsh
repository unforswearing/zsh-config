function file() {
  libutil:argtest "$1"
  # bkp filename.txt => filename.txt.bak
  # restore filename.txt => overwrites filename.txt
  function file.bkp() {
    /bin/cp "${1}"{,.bak}
  }
  function file.exists() {
    if [[ -s "${1}" ]]; then true; else false; fi
  }
  function file.copy() {
    <"${1}" | pbcopy
  }
  function file.read() {
    print "$(<${1})"
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
# directory actions
function dir() {
  libutil:argtest "$1"
  function dir.new() {
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
