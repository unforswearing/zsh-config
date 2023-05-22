# shellcheck shell=bash
# shellcheck disable=2145
# https://www.nushell.sh/book/commands/fetch.html
# https://www.nushell.sh/book/commands/post.html
# https://www.nushell.sh/book/commands/url_host.html
# https://www.nushell.sh/book/commands/url_path.html
# https://www.nushell.sh/book/commands/url_query.html
# https://www.nushell.sh/book/commands/url_scheme.html

function net() {
  uget() { nu -c "fetch ${@:-$(cat -)}"; }
  uput() { nu -c "put ${@:-$(cat -)}"; }
  url.host() { nu -c "\"${@:-$(cat -)}\" | url host"; }
  url.path() { nu -c "\"${@:-$(cat -)}\" | url path"; }
  url.query() { nu -c "\"${@:-$(cat -)}\" | url query"; }
  url.scheme() { nu -c "\"${@:-$(cat -)}\" | url scheme"; }

  case "$1" in
    fetch) shift; uget "$@" ;;
    put) shift; uput "$@" ;;
    url)
      local urlopt="$2"
      shift; shift;
      case "$urlopt" in
        host) url.host "$@" ;;
        path) url.path "$@" ;;
        query) url.query "$@" ;;
        scheme) url.scheme "$@" ;;
      esac
    ;;
  esac
}
