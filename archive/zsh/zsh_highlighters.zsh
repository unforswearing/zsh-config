  export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/usr/local/share/zsh-syntax-highlighting/highlighters
  export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor root line)
  typeset -A ZSH_HIGHLIGHT_PATTERNS
  ZSH_HIGHLIGHT_PATTERNS+=('rm -rf' 'fg=white,bold,bg=red')