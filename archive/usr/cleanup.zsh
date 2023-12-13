function cleanup() {
  function dir.rmempty() { find $(pwd) -type d -empty -print -delete; }
  function file.rmempty() { find $(pwd) -type f -empty -print -delete; }
  function rmempty() { file.rmempty && dir.rmempty; }
  function rm.dsstore() { find $(pwd) -name '*.DS_Store' -type f -ls -delete; }
  function rm.trash() { sudo rm -rf ~/.Trash/*; }
  case "$1" in
  empty)
    case "$2" in
    file) file.rmempty ;;
    dir) dir.rmempty ;;
    esac
    ;;
  dsstore) rm.dsstore ;;
  trash) rm.trash ;;
  *) rmempty && rm.dsstore ;;
  esac
}
