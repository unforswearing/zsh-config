################
# fs.zsh -> file system things
################
# # file / path stuff -------------------------
tilde() { hash -d "$1"="$PWD"; }
untilde() { unhash -d "$1"; }
up() {
  case "${1}" in
  "") cd .. || return ;;
  *) cd "$(eval "printf -- '../'%.0s {1..$1}")" || return ;;
  esac
}
path() { pwd; }
path.copy() { echo $(pwd)/"${2}" | pee "pbcopy" "echo $(pwd)/${1}"; }
path.abs() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }

files() { fd --type file --maxdepth="${1:-1}"; }
file.backup() { cp -i "${1}"{,.bak}; }
file.copy() { pbcopy <"$@"; }
file.exists() { test true -a "${1}" && echo true || echo false; }  # -a
file.isempty() { test true -s "${1}" && echo true || echo false; } # -s
file.new() { touch "$@"; }
# file.page() { <"${1:-<(cat -)}"; }
file.read() { echo "$(<"$1")"; }
file.restore() { cp "${1}"{.bak,}; }

copy() { file.copy "${@}"; }

dir() { fd --type directory --maxdepth="${1:-1}"; }
dir.exists() { test true -d "${1}" && echo true || echo false; }   # -d
dir.new() { 
  ccd() { mkdir -p "$1" && cd "$1"; }
  # mkdir "$@"; 
  case "$1" in
    "cd") 
      shift
      ccd "$1"
    ;;
    *) mkdir "$@" ;;
  esac
}
# var.exists() { test true -v "${1}" && echo true || echo false; }   # -v
# ---------------------------------------
# #######################################
ls.new() {
  # recency=2
  # ls.new $recency
  fd --type file \
    --base-directory ~/zsh-config/bin \
    --absolute-path \
    --max-depth=1 \
    --threads=2 \
    --change-newer-than "${1:-5}"min
}
# #######################################
rm.empty_files() { find . -type f -empty -print -delete; }
rm.empty_dirs() { find . -type d -empty -print -delete; }
rm.empty() { rm.empty_dirs && rm.empty_files; }
# #######################################
#
# app:exec() {
#   prepend_dir() { sd '^' "${1}"; }
#   exec_fzf() { fzf --query="${1}"; }
#   local list_all=$(
#     local homeapps="/Applications"
#     fd --prune -e "app" --base-directory "$homeapps" | prepend_dir "${homeapps}/"
#   )
#   open -a "$( print "${list_all}" | exec_fzf )" || print "exited";
# }