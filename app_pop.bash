prepend_dir() { sd '^' "${1}"; }
exec_fzf() { fzf --prompt=" " --color="bw,prompt:blue" --reverse --border; }
list_all() {
    local homeapps="/Applications"
    fd --prune -e "app" --base-directory "$homeapps" | prepend_dir "${homeapps}/"
}


open -a "$( list_all | exec_fzf )" && exit || exit 1
