### everything for zsh that is not a command goes here
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
  setopt no_bare_glob_qual
  setopt no_clobber
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
  source "$ZSH_PLUGIN_DIR/Tarrasch/zsh-colors/colors.plugin.zsh"
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

  # function terminate-current-job() { kill -s TERM %+ ; }
  # zle -N terminate-current-job terminate-current-job
  # bindkey "\e\e" kill-buffer
}
{
  source "${ZSH_USR_DIR}/lnks.bash"
  source "${ZSH_USR_DIR}/marks.bash"
  source "${ZSH_USR_DIR}/searchlink.bash"
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
}
{
  # use hardlinks to keep stuff in the zsh-config dir instead of home dir
  ln -sF ~/zsh-config/.zshenv ~/.zshenv
  ln -sF ~/zsh-config/.zshrc ~/.zshrc
  /bin/cp ~/zsh-config/.direnvrc ~/.direnvrc
  ln -sF ~/zsh-config/usr/hosts.py ~/hosts.py
}
