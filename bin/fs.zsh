################
# fs.zsh -> file system things
################
#
# # file / path stuff -------------------------
ccd() { mkdir -p "$1" && cd "$1"; }
tilde() { hash -d "$1"="$PWD"; }
untilde() { unhash -d "$1"; }
up() {
  case "${1}" in
  "") cd .. || return ;;
  *) cd "$(eval "printf -- '../'%.0s {1..$1}")" || return ;;
  esac
}
path() { echo $(pwd)/"${2}" | pee "pbcopy" "echo $(pwd)/${1}"; }
path.abs() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }

# alias -g new:dir='mkdir'
# alias -g new:file='touch'

files() { fd --type file --maxdepth="${1:-1}"; }
file.read() { echo "$(<"$1")"; }
file.backup() { cp -i "${1}"{,.bak}; }
file.restore() { cp "${1}"{.bak,}; }

file.copy() { pbcopy <"$@"; }
copy() { file.copy "${@}"; }

file.page() { <"$1"; }
page() { <"$1"; }

file.exists() { test true -a "${1}" && echo true || echo false; }  # -a
file.isempty() { test true -s "${1}" && echo true || echo false; } # -s
dir() { fd --type directory --maxdepth="${1:-1}"; }
dir.exists() { test true -d "${1}" && echo true || echo false; }   # -d
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
html::md() { pandoc -f html -t markdown "${1}"; }
md::html() { pandoc -f markdown -t html "${1}"; }
md::jupyter() { pandoc -f markdown -t ipynb "${1}"; }
# #######################################
rm.empty_files() { find . -type f -empty -print -delete; }
rm.empty_dirs() { find . -type d -empty -print -delete; }
rm.empty() { rm.empty_dirs && rm.empty_files; }
# #######################################
# source "$ZSH_CONFIG_DIR/plugin/thetic/extract/extract.plugin.zsh"
mp4::wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp4 <output_file>.wav"
  else
    ffmpeg -i "$1" "$2"
  fi
}
mp4::mp3() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42mp3 <input_file>.mp4 <output_file>.mp3"
  else
    ffmpeg -i "$1" -vn -acodec mp3 -ab 320k -ar 44100 -ac 2 "$2"
  fi
}
wav::mp3() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: wav2mp3 <input_file>.wav <output_file>.mp3"
  else
    echo "converting $1 to $2"
    sox "$1" -C 256 -r 44.1k "$2"
  fi
}
mp3::wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp3 <output_file>.wav"
  else
    sox "$1" "$2"
  fi
}
m4a::wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp3 <output_file>.wav"
  else
    ffmpeg -i "$1" -f sox - | sox -p "$2"
  fi
}
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