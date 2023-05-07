function wrap_quotes {
    echo $(printf '"%s"' "$@")
}