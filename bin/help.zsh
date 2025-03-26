# shellcheck shell=bash
environ "stdlib"
xman() { man "${1}" | man2html | browser; }
pman() { man -t "${1}" | open -f -a /Applications/Preview.app; }
sman() {
  # type a command to read the man page
  echo '' |
    fzf --prompt='man> ' \
      --height="$(tput lines)" \
      --padding=0 \
      --margin=0% \
      --preview-window=down,75% \
      --layout=reverse \
      --border \
      --preview 'man {q}'
}
