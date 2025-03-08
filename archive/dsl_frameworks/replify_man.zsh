function replify() {
  command="${*}"
  printf "Initialized REPL for [%s]
  " "$command"
  printf "%s> " "$command"
  read -r input
  while [ "$input" != "" ];
  do
      	eval "$command $input"
  	printf "
  %s> " "$command"
      	read -r input
  done
}
function xman() { man "${1}" | man2html | browser; }
function pman() {
  man -t "${1}" | open -f -a /Applications/Preview.app;
}
function sman() {
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