use::string >|/dev/null 2>&1
## ---------------------------------------------
# DSL FS
alias ll='exa $EXA_DEFAULT_OPTIONS'
alias ll.bw='exa $EXA_DEFAULT_OPTIONS --color=never'
alias ll.r='exa $EXA_DEFAULT_OPTIONS -R'
# file.backup filename.txt => filename.txt.bak
# file.restore filename.txt => overwrites filename.txt
function {newfile,fs.file.new}() { touch "$@"; }
function {readfile,fs.file.read}() { print "$(<"$1")"; }
function {copy,fs.file.copy}() { file.read "$1" | pbcopy; }
function {bkp,fs.file.backup}() { cp "${1}"{,.bak}; }
function {rst,fs.file.restore}() { cp "${1}"{.bak,} && rm "${1}.bak"; }
function {fexists,fs.file.exists}() { [[ -s "${1}" ]]; }
function {fempty,fs.file.isempty}() { [[ -a "${1}" ]] && [[ ! -s "${1}" ]]; }
# directory actions
function {newdir,fs.dir.new}() { mkdir "${1}"; }
function {readdir,fs.dir.read}() { ls "${1}"; }
function {dbkp,fs.dir.backup}() { cp -r "${1}" "${1}.bak"; }
function {drst,fs.dir.restore}() { cp -r "${1}.bak" "${1}" && rm -rf "${1}.bak"; }
function {pdir,fs.dir.parent}() { dirname "$(pwd)" &&}
function {dexists,fs.dir.exists}() { [[ -d "${1}" ]]; } 
function {dempty,fs.dir.isempty}() { 
  local count=$(ls -la "${1}" | wc -l | trim.left) 
  [[ $count -eq 0 ]];  
}
# fs prefix works for files and dirs
# filepath.abs "../../file.txt"
fs.path() { print "$(pwd)/${1}"; }
fs.abs() { print "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
fs.newer() { [[ "${1}" -nt "${2}" ]]; }
fs.older() { [[ "${1}" -ot "${2}" ]]; }
## ---------------------------------------------
green "dsl/filepath loaded"