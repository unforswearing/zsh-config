use::string >|/dev/null 2>&1
#############
# DSL FS
file.new() { touch "$@"; }
file.read() { print "$(<"$1")"; }
# file.backup filename.txt => filename.txt.bak
function {bkp,file.backup}() { cp "${1}"{,.bak}; }
# file.restore filename.txt => overwrites filename.txt
function {rst,file.restore}() { cp "${1}"{.bak,} && rm "${1}.bak"; }

file.exists() { [[ -s "${1}" ]]; }
file.isempty() { [[ -a "${1}" ]] && [[ ! -s "${1}" ]]; }

dir.new() { mkdir "${1}"; }
dir.read() { ls "${1}"; }
dir.backup() { cp -r "${1}" "${1}.bak"; }
dir.restore() { cp -r "${1}.bak" "${1}" && rm -rf "${1}.bak"; }

dir.exists() { [[ -d "${1}" ]]; } 
dir.isempty() { 
  local count=$(ls -la "${1}" | wc -l | trim.left) 
  [[ $count -eq 0 ]];  
}

filepath() { print "$(pwd)/${1}"; }
# filepath.abs "../../file.txt"
filepath.abs() { print "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }

# fs prefix works for files and dirs
fs.newer() { [[ "${1}" -nt "${2}" ]]; }
fs.older() { [[ "${1}" -ot "${2}" ]]; }

##########################################################################
green "dsl/filepath loaded"