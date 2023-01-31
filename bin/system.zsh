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
  "array" | "arr")
    local is_array=$(typeset + | grep -o "array.*${2}")
    [[ -n $is_array ]] && echo true || echo false
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
    #  "whitespace" | "ws")
    #    [[ "${2}" =~ $RE_WHITESPACE ]] && echo true || echo false
    #    ;;
  "upper") [[ "${2}" =~ $POSIX_UPPER ]] && echo true || echo false ;;
  "lower") [[ "${2}" =~ $POSIX_LOWER ]] && echo true || echo false ;;
  "alnum") [[ "${2}" =~ $POSIX_ALNUM ]] && echo true || echo false ;;
  "punct" | "punctuation") [[ "${2}" =~ $POSIX_PUNCT ]] && echo true || echo false ;;
  "newline") [[ "${2}" =~ $RE_NEWLINE ]] && echo true || echo false ;;
  "tab") [[ "${2}" =~ $RE_TAB ]] && echo true || echo false ;;
  "space") [[ "${2}" =~ $RE_SPACE ]] && echo true || echo false ;;
    # "dir")
    #  :: python "import os; os.path.isdir(\"${2}\")"
    #  ;;
    # "file")
    #  [ -e "${2}" ] && echo true || echo false
    #  ;;
  "empty_or_null" | "empty" | "null") [[ -z "${2}" || "${2}" == "null" ]] && echo true || echo false ;;
  "bool")
    [[ "${2}" == true || "${2}" == false || "${2}" -eq 0 || "${2}" -eq 1 ]] && echo true || echo false
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
    test $(is string "${2}") == true && test_truth_string "${2}" || test_truth_number "${2}"
    ;;
  "false")
    test $(is string "${2}") == true && test_truth_string "${2}" || test_truth_number "${2}"
    ;;
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
xman() { man "${1}" | man2html | browser; }
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
# retry() {
#   local retries=$1
#   shift
#   local count=0
#   until "$@"; do
#     local exit=$?
#     local wait=$((2 ** $count))
#     local count=$(($count + 1))
#     if [ $count -lt $retries ]; then
#       echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
#       sleep $wait
#     else
#       echo "Retry $count/$retries exited $exit, no more retries left."
#       return $exit
#     fi
#   done
#   return 0
# }