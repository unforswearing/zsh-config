# using 'security *-generic-password' as a simple k/v store
function addpass() {
  local key="${1}"; local value="${2}"
  security add-generic-password -a "$(whoami)" -s "${key}" -w "${value}"
}
function setkey() { addpass "$@"; }
function getpass() {
  local key="${1}"
  security find-generic-password -w -s "${key}" -a "$(whoami)"
}
function getkey () { getpass "$@"; }
function rmpass() {
  local key="${1}"
  security delete-generic-password -s "${key}" -a "$(whoami)"
}
function rmkey() { rmpass "$@"; }