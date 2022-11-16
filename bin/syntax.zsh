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
