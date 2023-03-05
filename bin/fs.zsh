################
# fs.zsh -> file system things
################
# # file / path stuff -------------------------
up() {
  case "${1}" in
  "") cd .. || return ;;
  *) cd "$(eval "printf -- '../'%.0s {1..$1}")" || return ;;
  esac
}
files() { fd --type file --maxdepth="${1:-1}"; }
copy() { file.copy "${@}"; }

dir() { fd --type directory --maxdepth="${1:-1}"; }
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
