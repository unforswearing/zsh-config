# shellcheck shell=bash
#  async "sleep 11 && print active_job" && await "print active_job completed"
function async() { { eval "$@" & } >/dev/null 2>&1 }
