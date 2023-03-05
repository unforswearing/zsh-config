#############
# DSL FS
file.backup() { cp -i "${1}"{,.bak}; }
file.exists() { test true -a "${1}" && print true || print false; }
file.isempty() { test true -s "${1}" && print true || print false; }
file.new() { touch "$@"; }
file.read() { print "$(<"$1")"; }
file.restore() { cp "${1}"{.bak,}; }

dir.exists() { test true -d "${1}" && print true || print false; } 
dir.new() { mkdir "${1}"; }

path() { pwd; }
path.cp() { print $(pwd)/"${2}" | pee "pbcopy" "print $(pwd)/${1}"; }
path.abs() { print "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }

##########################################################################
green "dsl/filepath loaded"