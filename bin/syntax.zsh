# these will only work interactively
# (because all aliases only work interacively? (not true))
__@() {
	{
	 	# if file, cat
		test -f "$1" && cat "$1" 2>/dev/null ||
		# if dir, ls
		test -d "$1" && ls "$1" 2>/dev/null
	} || {
		# if var, get vlaue
		<<<"$1" 2>/dev/null
	}
}
alias -g @='__@'
# ----------------
alias -g const='readonly'
alias -g tmp='local'

alias -g null='>/dev/null 2>&1'

alias -g arr='declare -a'
alias -g assoc='declare -A'

alias -g try='test'
alias -g and='&&'
alias -g not='!'
alias -g ifnot='||'

alias -g each='while read line' # :each; do $@; done

alias -g passthru='cat -'
alias -g async='&'
alias -g use='source'
alias -g filter='grep'

alias -g getin='read -r input && echo "$input"'

alias -g saveto='>'
alias -g clobber='>|'
alias -g appendto='>>'

# 6.5 Reserved Words
# The following words are recognized as reserved words when used as the first word of a
# command unless quoted or disabled using disable -r:
# do done esac then elif else fi for case if while function repeat time until
# select coproc nocorrect foreach end ! [[ { } declare export float integer
# local readonly typeset
# Additionally, ‘}’ is recognized in any position if neither the IGNORE_BRACES option nor the
# IGNORE_CLOSE_BRACES option is set.