    for var in "$@"
        do
            printf '%x' "$var";
        done
        printf '\n'