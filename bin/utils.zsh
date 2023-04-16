##
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
cpl() {
  unsetopt warn_create_global
  OIFS="$IFS"
  IFS=$'\n\t'
  local comm=$(history | gtail -n 1 | awk '{first=$1; $1=""; print $0;}')
  echo "${comm}" | pee "pbcopy" "cat - | sd '^\s+' ''"
  IFS="$OIFS"
  setopt warn_create_global
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
     port selfupdate; 
     db put macports_updated "$(gdate '+%Y-%m-%dT%H:%M')";
  } &) >|/dev/null 2>&1
}
update.tldr() {
  # update tldr (not really useful)
  green "updating tldr in the background"
  ({ tldr --update; 
     db put tldr_updated "$(gdate '+%Y-%m-%dT%H:%M')";
  } &) >|/dev/null 2>&1
}
update.brew() {
  # update homebrew
  green "updating homebrew in the background"
  ({ 
    brew update && brew upgrade; 
    db put homebrew_updated "$(gdate '+%Y-%m-%dT%H:%M')";
  } &) >|/dev/null 2>&1
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
