function array_to_json {
    # Passing the -n option to local causes the parameter to be a nameref variable
    local -n ARRAY=$1
    local VALUES=${ARRAY[@]}
    local VALUE=""
    local JSON=""

    for VALUE in ${VALUES}; do
        VALUE=$(wrap_quotes "$VALUE")
        JSON="$VALUE,$JSON"
    done

    # The json must be a minimum number of characters to be valid
    # Do not remove trailing slashes if empty
    if [ ${#JSON} -ge 1 ]; then
        JSON=${JSON::-1}
    fi

    echo "[$JSON]"
}