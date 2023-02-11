### everything for zsh that is not a command goes here
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
	source "$ZSH_PLUGIN_DIR/hlissner/zsh-autopair/autopair.zsh"
	source "$ZSH_PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
	source "$ZSH_PLUGIN_DIR/fzf-zsh/fzf-zsh-plugin.plugin.zsh"
	source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
	source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
	source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
}
{
	# ZLE --------------------------------------------------- ::
	autoload history-substring-search-up
	autoload history-substring-search-down
	zle -N history-substring-search-up
	zle -N history-substring-search-down
	# BINDKEY ----------------------------------------------- ::
	bindkey "^[[H" .backward-word # fn-left
	bindkey "^[[F" .forward-word  # fn-right
	bindkey '^[[A' history-substring-search-up
	bindkey '^[[B' history-substring-search-down
}
{
	zmodload zsh/regex
	autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
	add-zsh-hook chpwd chpwd_recent_dirs
	# run-help / help
	(($ + alaises[run - help])) && unalias run-help >/dev/null 2>&1

	autoload -Uz run-help
}
{
	# setopt 
	# setopt equals
	setopt hashall
	setopt interactive_comments
	setopt automenu
	setopt menucomplete
	setopt allexport
	setopt alwaystoend
	setopt c_precedences
	setopt cshjunkie_loops
	setopt cshjunkie_history
	setopt INC_APPEND_HISTORY
	setopt append_history
	setopt hist_expire_dups_first
	setopt hist_reduce_blanks
	setopt hist_lex_words
	setopt share_history
	setopt auto_cd
	setopt auto_pushd
	setopt cdable_vars
	setopt pushd_to_home
	setopt numeric_glob_sort
	setopt local_loops
	setopt sh_word_split
	setopt ksh_option_print
	setopt function_argzero
	setopt warn_create_global
	setopt bsd_echo
	setopt no_nomatch
	setopt no_bare_glob_qual
	setopt no_clobber
	setopt no_append_create
	# UNSETOPT ----------------------------------------------- ::
	# unsetopt bad_pattern
	unsetopt ksh_glob
	unsetopt monitor
}

# use hardlinks to keep stuff in the zsh-config dir instead of home dir
ln -sF ~/zsh-config/.zshenv ~/.zshenv
ln -sF ~/zsh-config/.zshrc ~/.zshrc 
ln -sF ~/zsh-config/usr/hosts.py ~/hosts.py
