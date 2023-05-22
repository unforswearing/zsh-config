# shellcheck shell=bash
_db_init() {
  # create the main db: $HOME/zsh-config_db.sql
  # sqlite3 "$HOME/zsh_db.db" "create table kv (key TEXT PRIMARY KEY, value VARCHAR);"
  # sqlite3 "$HOME/zsh_history.db "create table history (idx INTEGER PRIMARY KEY AUTOINCREMENT, val TEXT);"
  # exec zsh
  # db put db_init true
  :
}
db() {
  # a simple k/v db using sqlite ------------------------------------------
  local opt="$1"
  local key="$2"
  local val="$3"

  local zdb="/Users/unforswearing/zsh_db.db"
  
  local table="kv"
  local keyname="key"
  local valuename="value"

  # db hist get 405
  local histopt
  local idx
  if [[ $opt == "hist" ]]; then
    histopt="true"
    zdb="/Users/unforswearing/zsh_history.db"
  
    table="history"
    keyname="idx"
    valuename="val"
  
    shift

    opt="$1"
    key="$2"
    val="$3"
  fi

  case "$opt" in
  # db put fish delightful
  "put")
    if [[ $histopt == "true" ]]; then
      idx=$(sqlite3 ${zdb} "select idx from history order by idx desc limit 1");
      key="$(( ++idx ))"
      val=" $val"
    fi
    sqlite3 "${zdb}" "insert or replace into $table ($keyname, $valuename) values ('$key', '$val')"
    ;;
  # db get fish
  "get")
    sqlite3 "${zdb}" "select $valuename from $table where $keyname = '$key'"
    ;;
  # db delete fish
  "del" | "delete")
    sqlite3 "${zdb}" "delete from $table where $keyname = '$key'"
    ;;
  # db list
  "list" | "ls")
    sqlite3 "${zdb}" "select * from $table"
    ;;
  *) 
    red "error: '$opt' is not a db command" 
    echo "usage: db <put | get | del | list> [key] [value]"
    ;;
  esac
}
