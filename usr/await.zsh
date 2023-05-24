# shellcheck shell=bash
#  async "sleep 11 && print active_job" && await "print active_job completed"
environ "stdlib"
function await() { wait "$!" && { eval "$@" & } }
