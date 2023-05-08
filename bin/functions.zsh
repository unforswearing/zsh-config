# combining utils.zsh, conv.zsh, and fs.zsh
__@() {
  {
    # if file, cat
    test -f "$1" && cat "$1" 2>/dev/null ||
      # if dir, ls
      test -d "$1" && ls "$1" 2>/dev/null
  } || {
    # if var, get vlaue
    <<<"$1" 2>/dev/null
  }
}
alias -g @='__@'
# nushell system info
sys() {
  case $1 in
  host) nu -c "sys|get host" ;;
  cpu) nu -c "sys|get cpu" ;;
  disks) nu -c "sys|get disks" ;;
  mem | memory)
    nu -c "{
      free: (sys|get mem|get free), 
      used: (sys|get mem|get used),
      total: (sys|get mem|get total)
    }"
    ;;
  temp | temperature) nu -c "sys|get temp" ;;
  net | io) nu -c "sys|get net" ;;
  esac
}
memory() { sys memory; }
cpl() {
  unsetopt warn_create_global
  OIFS="$IFS"
  IFS=$'\n\t'
  local comm=$(history | gtail -n 1 | awk '{first=$1; $1=""; print $0;}')
  echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"
  IFS="$OIFS"
  setopt warn_create_global
}
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
rgb~hex() {
  unsetopt warncreateglobal
  for var in "$@"; do
    printf '%x' "$var"
  done
  printf '\n'
}
hex~rgb() {
  unsetopt warncreateglobal
  hex="$@"
  printf "%d %d %d\n" 0x${hex:0:2} 0x${hex:2:2} 0x${hex:4:2}
}
# #######################################
html~md() { pandoc -f html -t markdown "${1}"; }
md~html() { pandoc -f markdown -t html "${1}"; }
md~jupyter() { pandoc -f markdown -t ipynb "${1}"; }
# #######################################
mp4~wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp4 <output_file>.wav"
  else
    ffmpeg -i "$1" "$2"
  fi
}
mp4~mp3() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42mp3 <input_file>.mp4 <output_file>.mp3"
  else
    ffmpeg -i "$1" -vn -acodec mp3 -ab 320k -ar 44100 -ac 2 "$2"
  fi
}
wav~mp3() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: wav2mp3 <input_file>.wav <output_file>.mp3"
  else
    echo "converting $1 to $2"
    sox "$1" -C 256 -r 44.1k "$2"
  fi
}
mp3~wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp3 <output_file>.wav"
  else
    sox "$1" "$2"
  fi
}
m4a~wav() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "usage: mp42wav <input_file>.mp3 <output_file>.wav"
  else
    ffmpeg -i "$1" -f sox - | sox -p "$2"
  fi
}
###
xman() { man "${1}" | man2html | browser; }
pman() { man -t "${1}" | open -f -a /Applications/Preview.app; }
sman() {
  # type a command to read the man page
  echo '' |
    fzf --prompt='man> ' \
      --height=$(tput lines) \
      --padding=0 \
      --margin=0% \
      --preview-window=down,75% \
      --layout=reverse \
      --border \
      --preview 'man {q}'
}
external() {
  { # list commands installed with homebrew or macports
    port installed requested |
      grep 'active' | sd '^ *' '' | sd " @.*$" ""
    brew leaves
  } | sort -d
}
#
rm.trash() {
  sudo rm -rfv /Volumes/*/.Trashes
  sudo rm -rfv ~/.Trash
}
rm.ds_store() {
  find . -name '*.DS_Store' -type f -ls -delete
}

gist.new() {
  # $1 = description; $2 = file name
  gh gist create -d "$1" -f "$2"
}
update.macports() {
  # try to update macports (not sure if working)
  green "updating macports in the background"
  ({
    port selfupdate
    db put macports_updated "$(gdate '+%Y-%m-%dT%H:%M')"
  } &) >|/dev/null 2>&1
}
update.tldr() {
  # update tldr (not really useful)
  green "updating tldr in the background"
  ({
    tldr --update
    db put tldr_updated "$(gdate '+%Y-%m-%dT%H:%M')"
  } &) >|/dev/null 2>&1
}
update.brew() {
  # update homebrew
  green "updating homebrew in the background"
  ({
    brew update && brew upgrade
    db put homebrew_updated "$(gdate '+%Y-%m-%dT%H:%M')"
  } &) >|/dev/null 2>&1
}
