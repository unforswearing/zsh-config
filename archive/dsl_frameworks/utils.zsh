##
# Commented code can be converted to lua/teal
##
# debug() {
#   case "${1}" in
#   "t" | "true")
#     # sed -i 's/local DEBUG=false/local DEBUG=true/' ~/.zshrc
#     db put debug true
#     db put clear ""
#     ;;
#   "f" | "false")
#     # sed -i 's/local DEBUG=true/local DEBUG=false/' ~/.zshrc
#     db put debug false
#     db put clear "clear"
#     ;;
#   *) db get debug ;;
#   esac
# }
# declare -rg debug="debug"
# functions["debug"]="debug"
# alias -g debug="debug"
# ##
# log() { blue "$@"; }
# log.ok() { green "$@"; }
# log.warn() { yellow "$@"; }
# log.err() { red "$@"; }
##
# zc() {
#   function getfiles() fd . -t f --max-depth 2 "$1"
#   local currentdir=$(pwd)

#   local dirselection=$(
#     {
#       fd . -t d --max-depth 1 $ZSH_CONFIG_DIR
#       print "$ZSH_CONFIG_DIR/.zshrc"
#       print "$ZSH_CONFIG_DIR/.zshenv"
#     } | fzf
#   )

#   [[ -z $dirselection ]] && {
#     print "no directory selected."
#     return 1
#   }

#   cd "$currentdir"
#   local selectedfile=$(getfiles "$dirselection" | fzf)

#   [[ -z $selectedfile ]] && {
#     print "no file selected."
#   } || {
#     micro $selectedfile && cd "$currentdir"
#     exec zsh
#   }
# }

# app:exec() {
#   prepend_dir() { sd '^' "${1}"; }
#   exec_fzf() { fzf --query="${1}"; }
#   local list_all=$(
#     local homeapps="/Applications"
#     fd --prune -e "app" --base-directory "$homeapps" | prepend_dir "${homeapps}/"
#   )
#   open -a "$( print "${list_all}" | exec_fzf )" || print "exited";
# }
