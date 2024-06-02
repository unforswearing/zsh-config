@file() {
    unsetopt warn_create_global
    local name="$1"
    local path="$2"
    f.read() { cat $1; }
    f.write() { local f="$1"; shift; print "$@" >| "$f"; }
    # shellcheck disable=1009,1072,1073
    f.append() { local f="$1"; shift; print "$@" >>| "$f"; }
    f.copy() { local f="$1"; shift; /bin/cp "$f" "$2"; }
    f.close() { import gc && gc "$1"; }
    function f.open() {
      # f.open "name" "/path/name.txt"
      local ofile="$1"
      local oname="$(basename $1)"
      local ocontents="$(f.read)"
      local opath="$2"
      local ocreated="$(gstat -c %w $1)"
      local omodified="$(gstat -c %y $1)"
      eval "
      function $1() {
        function $1.name() { print $oname; }
        function $1.contents() { print $ocontents; }
        function $1.path() { print $opath; }
        function $1.created() { print $ocreated; }
        function $1.modified() { print $omodified; }
      }
      "
      print "
        name: $oname
        contents: $ocontents
        path: $opath
        created: $ocreated
        modified: $omodified
      "
    }
    declare -rg $name=$path
    functions[$name]="$(f.open $1 $2)"
    function _n() {
      function $name.read() { f.read $1; }
      function $name.write { local opt=$1; shift; f.write $opt $@; }
      function $name.append() { local opt=$1; shift; f.append $opt $@; }
      function $name.copy() { local opt=$1; shift; f.copy $opt "$@"; }
      function $name.close() { f.close $path; }
    }
    _n "$value"
  }
