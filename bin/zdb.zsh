#!/bin/zsh
db() {
  # a simple k/v db using sqlite ------------------------------------------
  readonly zdb="$HOME/zsh_db.db"
  local opt="$1"
  local key="$2"
  local val="$3"
  case "$opt" in
  "put")
    sqlite3 "${zdb}" "insert or replace into kv (key, value) values ('$key', '$val')"
    ;;
  "get")
    sqlite3 "${zdb}" "select value from kv where key = '$key'"
    ;;
  "del" | "delete")
    sqlite3 "${zdb}" "delete from kv where key = '$key'"
    ;;
  "list" | "ls")
    sqlite3 "${zdb}" "select * from kv"
    ;;
  *) 
    red "error: '$opt' is not a db command" 
    echo "usage: db <put | get | del | list> [key] [value]"
    ;;
  esac
}
