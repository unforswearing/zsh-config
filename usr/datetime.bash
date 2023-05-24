# shellcheck shell=bash
environ "stdlib"
# very simple time and date
# https://geek.co.il/2015/09/10/script-day-persistent-memoize-in-bash
datetime() {
  local opt="${1}"
  case "${opt}" in
  "day") gdate +%d ;;
  "month") gdate +%m ;;
  "year") gdate +%Y ;;
  "hour") gdate +%H ;;
  "minute") gdate +%M ;;
  "now") gdate --universal ;;
    # a la new gDate().getTime() in javascript
  "get_time") gdate -d "${2}" +"%s" ;;
  "add_days")
    local convtime
    convtime=$(st get_time "$(st now)")
    timestamp="$(st get_time "${2}")"
    day=${3:-1}
    gdate -d "$(gdate -d "@${timestamp}" '+%F %T')+${day} day" +'%s'
    ;;
  "add_months")
    declare timestamp month
    local convtime
    local ts
    convtime=$(st get_time "$(st now)")
    ts=$(st get_time "${2}")
    timestamp="${ts:$convtime}"
    month=${3:-1}
    gdate -d "$(gdate -d "@${timestamp}" '+%F %T')+${month} month" +'%s'
    ;;
  "add_weeks")
    declare timestamp week
    local convtime
    local ts
    convtime=$(st get_time "$(st now)")
    ts=$(st get_time "${2}")
    timestamp="${ts:$convtime}"
    week=${3:-1}
    gdate -d "$(gdate -d "@${timestamp}" '+%F %T')+${week} week" +'%s'
    ;;
  esac
}