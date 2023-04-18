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
    # sed -i 's/local DEBUG=false/local DEBUG=true/' ~/.zshrc
    db put debug true
    db put clear ""
    ;;
  "f" | "false")
    # sed -i 's/local DEBUG=true/local DEBUG=false/' ~/.zshrc
    db put debug false
    db put clear "clear"
    ;;
  *) db get debug ;;
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
zc() {
  function getfiles() fd . -t f --max-depth 2 "$1";
  local currentdir=$(pwd)

  local dirselection=$(
    { 
      fd . -t d --max-depth 1 $ZSH_CONFIG_DIR; 
      print "$ZSH_CONFIG_DIR/.zshrc"; 
      print "$ZSH_CONFIG_DIR/.zshenv"; 
    } | fzf
  ) 
  
  [[ -z $dirselection ]] && {
    print "no directory selected."
    return 1
  }

  cd "$currentdir"
  local selectedfile=$(getfiles "$dirselection" | fzf)

  [[ -z $selectedfile ]] && { 
    print "no file selected."
  } || {
    micro $selectedfile && cd "$currentdir"
    exec zsh
  }
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
