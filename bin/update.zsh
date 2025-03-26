# shellcheck shell=bash
environ "stdlib"
function update() {
  update.macports() {
    # try to update macports (not sure if working)
    color green "updating macports in the background"
    ({
      port selfupdate
      db put macports_updated "$(gdate '+%Y-%m-%dT%H:%M')"
    } &) >|/dev/null 2>&1
  }
  update.brew() {
    # update homebrew
    color green "updating homebrew in the background"
    ({
      brew update && brew upgrade
      db put homebrew_updated "$(gdate '+%Y-%m-%dT%H:%M')"
    } &) >|/dev/null 2>&1
  }
  case "$1" in
  ports) update.macports ;;
  brew) update.brew ;;
  esac
}
