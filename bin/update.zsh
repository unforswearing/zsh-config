update.macports() {
  # try to update macports (not sure if working)
  green "updating macports in the background"
  ({
    port selfupdate
    db put macports_updated "$(gdate '+%Y-%m-%dT%H:%M')"
  } &) >|/dev/null 2>&1
}
update.tldr() {
  # update tldr (not really useful)
  green "updating tldr in the background"
  ({
    tldr --update
    db put tldr_updated "$(gdate '+%Y-%m-%dT%H:%M')"
  } &) >|/dev/null 2>&1
}
update.brew() {
  # update homebrew
  green "updating homebrew in the background"
  ({
    brew update && brew upgrade
    db put homebrew_updated "$(gdate '+%Y-%m-%dT%H:%M')"
  } &) >|/dev/null 2>&1
}
