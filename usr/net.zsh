# https://www.nushell.sh/book/commands/fetch.html
# https://www.nushell.sh/book/commands/post.html
# https://www.nushell.sh/book/commands/url_host.html
# https://www.nushell.sh/book/commands/url_path.html
# https://www.nushell.sh/book/commands/url_query.html
# https://www.nushell.sh/book/commands/url_scheme.html
get() { nu -c "fetch ${@:-$(cat -)}"; }
put() { nu -c "put ${@:-$(cat -)}"; }
url.host() { nu -c "\"${@:-$(cat -)}\" | url host"; }
url.path() { nu -c "\"${@:-$(cat -)}\" | url path"; }
url.query() { nu -c "\"${@:-$(cat -)}\" | url query"; }
url.scheme() { nu -c "\"${@:-$(cat -)}\" | url scheme"; }
