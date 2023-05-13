# exports, hash, aliases, options, bindkey, import function, moving source files
{
  export KEYTIMEOUT=25
  export CLICOLOR=1
  export EDITOR="hx" #"nvim" #"micro"
  export GPG_TTY=$TTY
  # https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
  export HISTFILE="$HOME/.history"
  export HISTSIZE=50000000
  export SAVEHIST=10000000
  export HISTTIMEFORMAT='%F %T '
  export HISTIGNORE="exit:bg:fg:history:clear:reload"
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  export LSCOLORS=ExFxBxDxCxegedabagacad
  export PAGER="more"
  export PS2="  "
  export PERIOD=90000
  export SHELLFUNCS_DEFAULT_SHELL="/opt/local/bin/bash"
  export VISUAL="$EDITOR"
  export XDG_CACHE_HOME="${HOME}/.cache"
  export XDG_CONFIG_HOME="${HOME}/.config"
  export EXA_PERMISSIONS
  export EXA_DEFAULT_OPTIONS="--color auto --all --group-directories-first "
  EXA_DEFAULT_OPTIONS+="--long --header --modified --sort=name "
  EXA_DEFAULT_OPTIONS+="--git --time-style=iso --classify --no-permissions --no-user"
  export FZF_DEFAULT_OPTS="--border --exact --layout=reverse --no-bold --cycle"
  export GOPATH="$HOME/go"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=0
  export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/usr/local/share/zsh-syntax-highlighting/highlighters
  export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor root line)
  typeset -A ZSH_HIGHLIGHT_PATTERNS
  ZSH_HIGHLIGHT_PATTERNS+=('rm -rf' 'fg=white,bold,bg=red')
}
{
  # use short directory names
  # eg ~zbin instead of cd "$HOME/zsh-config/bin"
  hash -d zbin="$HOME/zsh-config/bin"
  hash -d zconf="$HOME/zsh-config"
  hash -d zetc="$HOME/zsh-config/etc"
  hash -d zlib="$HOME/zsh-config/lib"
  hash -d zplug="$HOME/zsh-config/plugin"
  hash -d cloud="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
  hash -d documents="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents"
  hash -d github="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/__Github"
  hash -d writing="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Freelance Writing/freelance_writing_obsidian"
  ## ---------------------------------------------
  # suffix aliases
  alias -s git='git clone'
  ## ---------------------------------------------
  # -g == global alias. global as in expands anywhere on the current line
  alias finder='open .'
  alias ls='ls -a'
  alias purj='sudo purge && sudo purge && sudo purge'
  alias pip='pip3'
  alias edit='micro' #'nvim'
  alias prev="cd -"
  alias c="pbcopy"
  alias p="pbpaste"
  alias cf='pbpaste|pbcopy'
  alias rm='rm -i'
  alias cp='cp -i'
  alias rmf='sudo rm -rf'
  alias plux='chmod +x'
  alias namesingle='vidir'
  alias sed='/usr/local/bin/gsed'
  alias togglewifi='networksetup -setairportpower en1 off && sleep 3 && networksetup -setairportpower en1 on'
}
{
  # setopt
  # setopt equals
  setopt allexport
  setopt alwaystoend
  setopt append_history
  setopt auto_cd
  setopt auto_pushd
  setopt automenu
  setopt bsd_echo
  setopt c_precedences
  setopt cdable_vars
  setopt cshjunkie_history
  setopt cshjunkie_loops
  setopt function_argzero
  setopt hashall
  setopt hist_expire_dups_first
  setopt hist_lex_words
  setopt hist_reduce_blanks
  setopt inc_append_history
  setopt interactive_comments
  setopt ksh_option_print
  setopt ksh_zero_subscript
  setopt local_loops
  setopt menucomplete
  setopt no_append_create
  setopt no_clobber
  setopt no_bare_glob_qual
  setopt no_nomatch
  setopt numeric_glob_sort
  setopt pushd_to_home
  setopt sh_word_split
  setopt share_history
  setopt warn_create_global
  # UNSETOPT ----------------------------------------------- ::
  # unsetopt bad_pattern
  unsetopt ksh_glob
  unsetopt monitor
}
{
  zstyle ':completion:*' use-cache yes
  zstyle ':completion:*' cache-path $ZSH_CACHE_DIR
  zstyle ':completion:*' fzf-search-display true
  zstyle ':chpwd:*' recent-dirs-default
  zstyle ':chpwd:*' recent-dirs-file
  zstyle recent-dirs-file ':chpwd:*' ${ZDOTDIR:-$HOME}/.chpwd-recent-dirs-${TTY##*/} +
  zstyle ':chpwd:*' recent-dirs-insert 'both'
  # complete 'cd -<tab>' with menu
  zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
  # insert all expansions for expand completer
  zstyle ':completion:*:expand:*' tag-order all-expansions
  zstyle ':completion:*:history-words' list false
  # activate menu
  zstyle ':completion:*:history-words' menu yes
  zstyle ':completion:*:matches' group 'yes'
  zstyle ':completion:*:options' description 'yes'
  zstyle ':completion:*' verbose true
}
{
  # source "$ZSH_PLUGIN_DIR/Tarrasch/zsh-colors/colors.plugin.zsh"
  source "$ZSH_PLUGIN_DIR/hlissner/zsh-autopair/autopair.zsh"
  source "$ZSH_PLUGIN_DIR/fzf-zsh/fzf-zsh-plugin.plugin.zsh"
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
  source "$ZSH_PLUGIN_DIR/3v1n0/zsh-bash-completions-fallback/zsh-bash-completions-fallback.plugin.zsh"
}
{
  # zmodload zsh/regex
  autoload fzf-tab
  autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
  add-zsh-hook chpwd chpwd_recent_dirs
  # run-help / help
  (($ + alaises[run - help])) && unalias run-help >/dev/null 2>&1
  autoload -Uz run-help

  # ZLE --------------------------------------------------- ::
  autoload history-substring-search-up
  autoload history-substring-search-down
  zle -N history-substring-search-up
  zle -N history-substring-search-down
  # BINDKEY ----------------------------------------------- ::
  bindkey "^[[H" backward-word # fn-left
  bindkey "^[[F" forward-word  # fn-right
  bindkey "^[[A" history-substring-search-up
  bindkey "^[[B" history-substring-search-down
  bindkey '\e' vi-kill-line
}
{
  # move stuff from $HOME to zconf/
  /bin/mv "${HOME}/.zshenv" "${ZSH_CONFIG_DIR}/log/"
  /bin/mv "${HOME}/.zshrc" "${ZSH_CONFIG_DIR}/log/"
  /bin/mv "${HOME}/.direnvrc" "${ZSH_CONFIG_DIR}/log/"
  /bin/mv "${HOME}/hosts.py" "${ZSH_CONFIG_DIR}/log/"

  # copy stuff from zconf to $HOME
  /bin/cp "${HOME}/zsh-config/.zshenv" "${HOME}/.zshenv"
  /bin/cp "${HOME}/zsh-config/.zshrc" "${HOME}/.zshrc"
  /bin/cp "${HOME}/zsh-config/.direnvrc" "${HOME}/.direnvrc"
  /bin/cp "${HOME}/zsh-config/hosts.py" "${HOME}/hosts.py"

}
