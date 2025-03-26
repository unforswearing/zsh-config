# shellcheck shell=bash
#environ "stdlib"
# shellcheck disable=2145

  red="\033[31m"
  green="\033[32m"
  yellow="\033[33m"
  blue="\033[34m"
  reset="\033[39m"
  black="\033[30m"
  white="\033[37m"
  magenta="\033[35m"
  cyan="\033[36m"
  opt="$1"
  shift
  case "$opt" in
    red) print "${red}$@${reset}" ;;
    green) print "${green}$@${reset}" ;;
    yellow) print "${yellow}$@${reset}" ;;
    blue) print "${blue}$@${reset}" ;;
    black) print "${black}$@${reset}" ;;
    white) print "${white}$@${reset}" ;;
    magenta) print "${magenta}$@${reset}" ;;
    cyan) print "${cyan}$@${reset}" ;;
    help) print "colors <red|green|yellow|blue|black|magenta|cyan> string" ;;
  esac
