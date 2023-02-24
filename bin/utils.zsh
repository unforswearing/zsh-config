##
debug() {
  case "${1}" in
  "t" | "true")
    sed -i 's/local DEBUG=false/local DEBUG=true/' ~/.zshrc
    sed -i "s/local CLEAR='clear'/local CLEAR=/" ~/.zshrc
    ;;
  "f" | "false")
    sed -i 's/local DEBUG=true/local DEBUG=false/' ~/.zshrc
    sed -i "s/local CLEAR=/local CLEAR='clear'/" ~/.zshrc
    ;;
  *) echo $DEBUG ;;
  esac
}
declare -rg debug="debug"
functions["debug"]="debug"  
alias -g debug="debug"
## 
log() { blue "$@"; }
log.ok() { green "$@"; }
log.warn() { yellow "$@"; }
log.err() { red "$@"; }
# hot reload recently updated files w/o reloading the entire env
hs() {
  hash -r 
  # save the current dir
  pwd >|"$HOME/.zsh_reload.txt"
  db put "reload_dir" "$(pwd)"

  unsetopt warn_create_global
  source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  # attemt to hot reload config files
  fd --type file \
    --base-directory ~/zsh-config/bin \
    --absolute-path \
    --max-depth=1 \
    --threads=2 \
    --change-newer-than 1min |
    # source all recently updated files
    while read item; do source "${item}"; done
  setopt warn_create_global
}
declare -rg hs="hs"
functions["hs"]="hs"  
alias -g hs="hs"
##
# # typecheck -------------------------------------------
is() {
  unsetopt warn_create_global
  local opt="${1}"
  case "${opt}" in
  "function" | "fun")
    local is_function
    is_function=$(type -w "$2" | awk -F: '{print $2}' | trim.left)
    [[ ${is_function} == "function" ]] && echo true || echo false
    ;;
  "number" | "num" | "int")
    [[ "${2}" =~ $RE_NUMBER ]] && echo true || echo false
    ;;
  "string" | "str")
    [[ "${2}" =~ $RE_ALPHA ]] && echo true || echo false
    ;;
  "set" | "declared" | "decl")
    local alt_opt="${2}"
    [[ -n $alt_opt ]] && echo true || echo false
    ;;
  "unset" | "empty")
    local alt_opt="${2}"
    [[ -z $alt_opt ]] && echo true || echo false
    ;;
  "upper") [[ "${2}" =~ $POSIX_UPPER ]] && echo false || echo true ;;
  "lower") [[ "${2}" =~ $POSIX_LOWER ]] && echo false || echo true ;;
  "alnum") [[ "${2}" =~ $POSIX_ALNUM ]] && echo false || echo true ;;
  "punct") [[ "${2}" =~ $POSIX_PUNCT ]] && echo false || echo true ;;
  "newline") [[ "${2}" =~ $RE_NEWLINE ]] && echo true || echo false ;;
  "tab") [[ "${2}" =~ $RE_TAB ]] && echo true || echo false ;;
  "space") [[ "${2}" =~ $RE_SPACE ]] && echo true || echo false ;;
  "empty_or_null" | "empty" | "null") 
    [[ -z "${2}" || "${2}" == "null" ]] && {
      echo false 
    } || {
      echo true
    }
    ;;
  # the 'test_truth_string' function will only load
  # if "$opt" is true or false. the ';&' at the end of 
  # this section is a pass through -- test_truth_string
  # is available in the context of options "true" and "false"
  "true" | "false")
    test_truth_string() {
      test "$1" == "true" && echo true || echo false
    }
    test_truth_number() {
      test "$1" -eq 0 && echo true || echo false
    }
    ;&
  "true")
    test $(is string "${2}") == true && {
      test_truth_string "${2}" 
    } || {
      test_truth_number "${2}"
    }
    ;;
  "false")
    test $(is string "${2}") == true && {
      test_truth_string "${2}" 
    } || {
      test_truth_number "${2}"
    }
    ;;
  "bool") echo "bool is not a valid option." ;;
  *)
    [[ "${1}" =~ ${2} ]] && echo true || echo false
    ;;
  esac
  setopt warn_create_global
}
declare -rg is="is"
functions["is"]="is"  
alias -g is="is"
##
# very simple time and date
# https://geek.co.il/2015/09/10/script-day-persistent-memoize-in-bash
datetime() {
  local opt="${1}"
  case "${opt}" in
    "day") gdate +%d ;;
    "month") gdate +%m ;;
    "year") gdate +%Y ;;
    "hour") gdate +%H ;;
    "minute") gdate +%M ;;
    "now") gdate --universal ;;
      # a la new gDate().getTime() in javascript
    "get_time") gdate -d "${2}" +"%s" ;;
  esac
}
# nushell system info
sys() {
  case $1 in
  host) lang nu "sys|get host" ;;
  cpu) lang nu "sys|get cpu" ;;
  disks) lang nu "sys|get disks" ;;
  mem | memory) lang nu "sys|get mem" ;;
  temp | temperature) lang nu "sys|get temp" ;;
  net | io) lang nu "sys|get net" ;;
  esac
}
lang() {
  # language stuff ===========
  case "$1" in
  lua) /usr/local/bin/lua -e "$2" ;;
  node | js) /usr/local/bin/node -e "$2" ;;
  nu) /Users/unforswearing/.cargo/bin/nu -c "$2" ;;
  python | py) /opt/local/bin/python -c "$2" ;;
  typescript | ts) /usr/local/bin/ts-node -e "$2" ;;
  esac
}
cpl() {
  unsetopt warn_create_global
  OIFS="$IFS"
  IFS=$'\n\t'
  local comm=$(history | gtail -n 1 | awk '{first=$1; $1=""; print $0;}')
  echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"
  IFS="$OIFS"
  setopt warn_create_global
}
# inspied by nushell
skip() { awk '(NR>'"$1"')'; }
drop() { ghead -n -"$1"; }
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
# from various githubs and gists around the internet
confirm() {
  vared -p  "Are you sure? [y/N] " -c response
  case "$response" in
    [yY][eE][sS]|[yY])
      true
    ;;
    *) false ;;
    esac
}
rm.trash() {
  sudo rm -rfv /Volumes/*/.Trashes
  sudo rm -rfv ~/.Trash
}
rm.ds_store() {
  find . -name '*.DS_Store' -type f -ls -delete
}
flush() {
  dscacheutil -flushcache
}
repair() {
  diskutil repairPermissions /
}
ip() {
  dig +short myip.opendns.com @resolver1.opendns.com
}
ip.local() {
  ipconfig getifaddr en1
}
gist.new() {
  # $1 = description; $2 = file name
  gh gist create -d "$1" -f "$2"
}
# app:exec() {
#   prepend_dir() { sd '^' "${1}"; }
#   exec_fzf() { fzf --query="${1}"; }
#   local list_all=$(
#     local homeapps="/Applications"
#     fd --prune -e "app" --base-directory "$homeapps" | prepend_dir "${homeapps}/"
#   )
#   open -a "$( print "${list_all}" | exec_fzf )" || print "exited";
# }
