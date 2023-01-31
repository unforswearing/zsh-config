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
alias -g :here='.'
alias -g :use='source'
alias -g :bkg='&'
alias -g :hide='&'
alias -g :this='cat -'
alias -g :dump='cat'
alias -g :tmp='local'
alias -g :const='readonly'
alias -g :array='declare -a'
alias -g :assoc='declare -A'
alias -g :if='test'
alias -g :then='&&'
alias -g :else='||'
alias -g :not='!'
alias -g not='!'
alias -g :match='grep'
# the alias '::' can only be used after closing bracket
#    and not a semicolon!
alias -g ::='done'
# ls | :foreach line; do {
#	echo $line
# } ::
alias -g :foreach='while read'
alias -g :each='while read line' # :each; do $@; done
alias -g :in='read -r input && echo "$input"'
alias -g :out='echo'

# syntax that adds or removes files /dirs is not prepended with ':'
alias -g redo='eval $(cpl)'
alias -g saveas='>'
alias -g replaces='>|'
alias -g appendto='>>'
alias -g new:dir='mkdir'
alias -g new:file='touch'

# 6.5 Reserved Words
# The following words are recognized as reserved words when used as the first word of a
# command unless quoted or disabled using disable -r:
# do done esac then elif else fi for case if while function repeat time until
# select coproc nocorrect foreach end ! [[ { } declare export float integer
# local readonly typeset
# Additionally, ‘}’ is recognized in any position if neither the IGNORE_BRACES option nor the
# IGNORE_CLOSE_BRACES option is set.