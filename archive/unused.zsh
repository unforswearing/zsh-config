## see also extension.zsh
# alias zvm='source "$ZSH_PLUGIN_DIR/zsh-vi-mode/zsh-vi-mode.plugin.zsh"'
alias mkdir='nocorrect mkdir'
alias rmd='bash $HOME/Documents/__Github/rmd-cli/rmd.bash'
# micro micro editor config files
alias m.bindings='micro ~/.config/micro/bindings.json'
alias m.settings='micro ~/.config/micro/settings.json'
alias m.init='micro ~/.config/micro/init.lua'
#setenv() { local all="$@"; typeset -x "${1}${1:+=}${(@)argv[2,$#]}" }
quote() {
  local opt="${1}"
  case "${opt}" in
  "remove")
    shift
    local q="$@"
    q="${q//\'/}"
    q="${q//\"/}"
    echo $q
    ;;
  "wrap")
    shift
    local q="$@"
    echo "\"$(quote remove ${q})\""
    ;;
  esac
}
google() {
  local srch=$(<$@ | sd ' ' '+')
  print $srch
  open "https://www.google.com/search?q=${srch}"
}
srch() {
  local query=$(<<<"$@" | sd " " "+")
  open "https://duckduckgo.com/?q=$query"
}
# limit functions to 3 arguments
# fn echo "args = $argv = $@"
alias {fn,func,λ}='function { argv=$(echo $argv[1,3]);'
rule() { printf "%$(tput cols)s\n" | tr " " "─"; }
hprev() { eval "history | tail -n 1 | sd '[0-9]+(\s+)+' '' | trim.left"; }
alias now="$(command -v gdate) \"+%Y-%m-%dT%H:%M\""
alias micro='dtach -a m || dtach -A m micro'
# for f in /etc/zshrc{,.d/**/*}(.N) $HOME/.zshrc.d/**/*(.N); do . "$f"; done
alias gui='open -a'
export ZZ="$ZSH_CONFIG_DIR"
# # short   eat command -------------------------------------------
rpt() {
  local n="${1:-$(cat -)}"
  shift
  repeat "${n}"
  # do "$@"; done;
}
edit.var() { vared "$@"; }
edit.fun() { zed -f "$@"; }
## a very simple data structure --------------------------
pair() { echo "${1};${2}"; }
pair.delim() { echo "${1}""${3}""${2}"; }
pair.first() { echo "${1:-$(cat -)}" | awk -F";" '{print $1}'; }
pair.last() { echo "${1:-$(cat -)}" | awk -F";" '{print $2}'; }
typeof() {
  # Bash-compatible(ish) -t support for type
  function _type {
    emulate -L zsh
    setopt no_unset warn_create_global
    local saw_dash_t=0
    local arg
    for arg in "$@"; do
      if [[ $arg == -t ]]; then
        saw_dash_t=1
      elif [[ $arg == -a ]]; then
        continue
      elif [[ ${arg:0:1} != - ]]; then
        break
      fi
    done
    if ((!saw_dash_t)); then
      builtin type "$@"
      return $?
    fi
    integer i
    integer i_idx
    declare -a args
    args=("$@")
    for ((i = 1; i <= $#; i++)); do
      if [[ ${args[$i]} == -t ]]; then
        i_idx=$i
      fi
    done
    #args[$i_idx]=()
    set -- $args
    declare -A types
    declare -a lines
    #lines=( "${(@f)$(whence -w "$@")}" )
    local line
    for line in "$lines"; do
      local kv
      #kv=( "${(@s/: /)line}" )
      echo ${kv[2]}
    done
  }
  _type "$@"
}
amp() { git add . && git commit -m "$1" && git push; }
kiosk() {
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --kiosk \
    --app="https://${1}"
}
alias textedit='/Applications/TextEdit.app/Contents/MacOS/TextEdit'
# send output to dev/null
# eg. echo "stupid stuff" stdnull
alias stdnull=':>/dev/null'
alias sqlite='sqlite3'
alias finder='open .'
alias tcl='/usr/local/opt/tcl-tk/bin/tclsh'
alias sedit='$(echo -en "nvim\nmicro\nsubl\ncode" | fzf)'
cloud="/Users/unforswearing/Library/Mobile Documents/com~apple~CloudDocs"
alias notes='glow "$cloud"/Documents/Notes'
# match $pattern in string|file|dir
match() {
  local pattern="$1"
  local location="$3"
  local opt="$4"
  case "$3" in
  "string") <<<"$opt" | grep $pattern ;;
  "file") rg "$pattern" "$opt" ;;
  "dir") fd "$pattern" --max-depth 1 ;;
  esac
}
file() {
  local opt="${1}"
  local xopt="${2}"
  local yopt="${3}"
  local zopt="${4}"
  case "${opt}" in
  "read") echo "$(<"$xopt")" ;;
  "rename") mv -i "${xopt}" "${yopt}" ;;
  "backup") cp -i "$xopt"{,.bak} ;;
  "restore") cp "$xopt"{.bak,} ;;
  "mcd") mkdir -p "$xopt" && cd "$xopt" ;;
  "path") echo "$(pwd)"/"${xopt}" ;;
  "new")
    case "$xopt" in
    "file") touch "$yopt" ;;
    "dir") mkdir "$yopt" ;;
    esac
    ;;
  "del")
    case "$xopt" in
    "file") if [ -e "$yopt" ]; then
      rm "$yopt"
      return $?
    fi ;;
    "dir") if [ -e "$yopt" ]; then
      rm -irf "$yopt"
      return $?
    fi ;;
    esac
    ;;
  "convert")
    case "$xopt" in
    "mp42wav")
      if [[ -z "$yopt" ]] || [[ -z "$zopt" ]]; then
        echo "usage: mp42wav <input_file>.mp4 <output_file>.wav"
      else
        ffmpeg -i "$yopt" "$zopt"
      fi
      ;;

    "mp42mp3")
      if [[ -z "$yopt" ]] || [[ -z "$zopt" ]]; then
        echo "usage: mp42mp3 <input_file>.mp4 <output_file>.mp3"
      else
        ffmpeg -i "$yopt" -vn -acodec mp3 -ab 320k -ar 44100 -ac 2 "$zopt"
      fi
      ;;
    "wav2mp3")
      if [[ -z "$yopt" ]] || [[ -z "$zopt" ]]; then
        echo "usage: wav2mp3 <input_file>.wav <output_file>.mp3"
      else
        echo "converting $1 to $2"
        sox "$yopt" -C 256 -r 44.1k "$zopt"
      fi
      ;;

    "mp32wav")
      if [[ -z "$yopt" ]] || [[ -z "$zopt" ]]; then
        echo "usage: mp42wav <input_file>.mp3 <output_file>.wav"
      else
        sox "$yopt" "$zopt"
      fi
      ;;

    "m4a2wav")
      if [[ -z "$yopt" ]] || [[ -z "$zopt" ]]; then
        echo "usage: mp42wav <input_file>.mp3 <output_file>.wav"
      else
        ffmpeg -i "$yopt" -f sox - | sox -p "$zopt"
      fi
      ;;
    *)
      pandoc -o "$yopt" "$xopt"
      ;;
    esac
    ;;
  esac
}
.ext() {
  local ext="${1}" && shift
  fd -uu -i --max-depth 1 --extension "${ext}" "${@}"
}
# does dir exist as subfolder of current dir
.dir() {
  local srch="${1}" && shift
  fd -uu --max-depth 1 -t d "${srch}" "${@}"
}
.file() {
  local ext="${name}" && shift
  fd --uu --max-depth 1 --type file "${name}" "${@}"
}
valueof() {
  local opt="${1}"
  (($ + opt)) && echo $(
    set | grep ^$opt= | awk -F'=' '{print $2}'
  )
}
################
# nu shell -> zsh
###########################
# https://www.nushell.sh/book/commands/fetch.html
# https://www.nushell.sh/book/commands/post.html
# https://www.nushell.sh/book/commands/url_host.html
# https://www.nushell.sh/book/commands/url_path.html
# https://www.nushell.sh/book/commands/url_query.html
# https://www.nushell.sh/book/commands/url_scheme.html
get() { nu -c "fetch ${@:-$(cat -)}"; }
put() { nu -c "put ${@:-$(cat -)}"; }
url.host() { nu -c "\"${@:-$(cat -)}\" | url host"; }
url.path() { nu -c "\"${@:-$(cat -)}\" | url path"; }
url.query() { nu -c "\"${@:-$(cat -)}\" | url query"; }
url.scheme() { nu -c "\"${@:-$(cat -)}\" | url scheme"; }
alias ched='export EDITOR=$(echo -en "nvim\nmicro\nemacs\nhx" | fzf)'
# create or mutate a variable
mut() {
  vared -c -p "$1 = " "${1}"
}
fixgit() {
  function gitcheckmaster() {
    remote="$(git remote -v | awk -F" " '{print $1}' | ghead -n 1)"
    git fetch "$remote"
    git status
  }

  function gitfixcommit() {
    remote="$(git remote -v | awk -F" " '{print $1}' | ghead -n 1)"
    echo "Pulling commit from "$remote""

    git pull "$remote" master
    echo "run 'git push "$remote" master' to push commit change to "$remote""
  }

  function gitfixignore() {
    git rm -r --cached .
  }

  # from https://stackoverflow.com/questions/1125968/how-do-i-force-git-pull-to-overwrite-local-files
  function gitrmlocal() {
    # overwrite local changes by pulling remote
    _do() {
      git fetch --all
      git reset --hard origin/master
    }

    echo "This command will overwrite all local changes."
    read -p "Are you sure you want to proceed with this action? (y/n) " yn

    case "$yn" in
    [yY]*) _do ;;
    *) echo "Will not overwrite local changes." ;;
    esac
  }

  function gitfixstash() {
    _do() {
      rm .git/refs/stash .git/logs/refs/stash
    }

    if [ -d ./git ]; then
      echo "This command will remove '.git/refs/stash' or '.git/logs/refs/stash'"
      read -p "Are you sure you want to proceed with this action? (y/n) " yn

      case "$yn" in
      [yY]*) _do ;;
      *) echo "Will not remove '.git/refs/stash' or '.git/logs/refs/stash'." ;;
      esac
    else
      echo ".git/ not found. Are you in the root folder of this project?"
    fi
  }

  function gitremovechanges() {
    echo "This command will remove all tracked changes from this directory"
    read -p "Are you sure you want to proceed with this action (y/n) " yn
    case "$yn" in
    yY) git reset --hard && git clean -f -d ;;
    *) echo "Will not remove tracked changes" ;;
    esac
  }

  function giteradicatefile() {
    # script $2, not function $2
    echo "removing file: $2"
    read -p "Are you sure you want to proceed with this action (y/n) " yn
    case "$yn" in
    yY) git filter-branch -f --tree-filter "git rm -rf --cached --ignore-unmatch ${2}" HEAD ;;
    *) echo "Will not remove tracked changes" ;;
    esac
  }

  case "$1" in
  badfile) giteradicatefile ;;
  commit) gitfixcommit ;;
  ignore) gitfixignore ;;
  local) gitrmlocal ;;
  stash) gitfixstash ;;
  status) gitcheckmaster ;;
  *) echo "usage: fixgit [badfile | commit | ignore | local | stash | status]" ;;
  esac
}
ccdt() { ccd ~/tmp/$(date "+%y%m%d"); }
# source a file if it exists, warn if not
source() {
  if [[ $# -ne 1 ]]; then
    print -u 2 "Usage: source file"
    return 1
  fi
  if [[ -f "$1" ]]; then
    source "$1"
  else
    print -u 2 "'$1' does not exist"
  fi
}
fd::ext() {
  local ext="${1}" && shift
  fd --hidden --max-depth 1 --extension "${ext}" "${@}"
}

fd::dir() {
  local ext="${1}" && shift
  fd --hidden --max-depth 1 --type dir "${ext}" "${@}"
}

fd::file() {
  local ext="${1}" && shift
  fd --hidden --max-depth 1 --type file "${ext}" "${@}"
}
manps() {
  if [ -z "$1" ]; then
    echo usage: $FUNCNAME topic
    echo This will open a PostScript formatted version of the man page for \'topic\'.
  else
    man -t $1 | open -f -a /Applications/Preview.app
  fi
}
preexec_alt_var_syntax() {
  local current="${1}"
  #   echo "${current}" | awk '{for (i=2; i<=NF;i++) print $i}' | tr ' ' '\n' >>"$HOME/.zsh_args"
  #   # make all vars readonly?
  #  create_typed_function "${current}"
  typemismatcherror() { echo "type mismatch: $1 is not type $2" }
  #   # set non function types
  #   # varname : type -> value
  local name
  local value
  local vtype
  local composed
  if [[ $current =~ ' : (str(ing)?|num(ber)?|arr(ay)?) ->'  ]] && {
    name=$(echo $current | awk -F":" '{print $1}' | trim)
    value=$(echo $current | awk -F"->" '{print $2}'| trim)
    vtype=$(echo $current | awk -F"->" '{print $1}' | sd "$name :" "" | trim)
  case $vtype in
    "str"|"string")
      var_declaration="declare -rx"
      [[ $(assert str $value) ]] && { 
        composed="$name=\"$value\""
        eval "declare -r" "$composed" 
      } || {
        typemismatcherror "$value" "string"
      }
    ;;
    "num"|"number")
      [[ $(assert number $value) ]] && {
      composed="$name=$value"
      eval "declare -ir" "$composed"
      } || { 
        typemismatcherror "$value" "number" 
      }
    ;;
  "arr"|"array")
    [[ $(assert array ("$value")) ]] && {
    composed="declare -ax $name=$value"
    eval $composed
    } || { 
      typemismatcherror "$value" "array" 
    }
    ;;
  esac
}
# use: 
# range.foreach \
#   --index_variable="idx" \
#   --value_variable="val" \ 
#   {$range_start..$range_end} \ 
#   "$(cat << 'EOF' \
# echo "$idx has value $val"
# EOF
#
and() { (($? == 0)) && "$@"; }
or() { (($? == 0)) || "$@"; }
defer() {
  source "$ZSH_CONFIG_DIR/plugin/romkatv/zsh-defer/zsh-defer.plugin.zsh" &&
    zsh-defer "$@"
}
