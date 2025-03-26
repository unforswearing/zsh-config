# hot reload recently updated files w/o reloading the entire env
hs() {
  hash -r 
  # save the current dir
  pwd >|"$HOME/.zsh_reload.txt"
  db put "reload_dir" "$(pwd)"

  unsetopt warn_create_global
  source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  # attemt to hot reload config files
  fd --type file \
    --base-directory ~/zsh-config/bin \
    --absolute-path \
    --max-depth=1 \
    --threads=2 \
    --change-newer-than 1min |
    # source all recently updated files
    while read item; do source "${item}"; done
  setopt warn_create_global
}
declare -rg hs="hs"
functions["hs"]="hs"  
alias -g hs="hs"