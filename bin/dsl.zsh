# DSL.ZSH
# this file contains code that attempts to make zsh more like a 
# traditional programming language via new keywords, env variables, and "objects"
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
alias -g let='local'

alias -g nil='>/dev/null 2>&1'

alias -g arr='declare -a'
alias -g assoc='declare -A'

alias -g try='test'
alias -g and='&&'
alias -g not='!'
alias -g ifnt='||'

alias -g each='while read line' # :each; do $@; done

alias -g use='source'

alias -g stdin='read -r input && echo "$input"'
alias -g stdout='print'

alias -g saveto='>'
alias -g clobber='>|'
alias -g appendto='>>'

# 6.5 Reserved Words
# The following words are recognized as reserved words when 
# used as the first word of a
# command unless quoted or disabled using disable -r:
# do done esac then elif else fi for case if while function repeat time until
# select coproc nocorrect foreach end ! [[ { } declare export float integer
# local readonly typeset
# Additionally, ‘}’ is recognized in any position if neither 
# the IGNORE_BRACES option nor the
# IGNORE_CLOSE_BRACES option is set.

################
export RE_ALPHA="[aA-zZ]"
export RE_STRING="([aA-zZ]|[0-9])+"
export RE_WORD="\w"
export RE_NUMBER="^[0-9]+$"
export RE_NUMERIC="^[0-9]+$"
export RE_NEWLINE="\n"
export RE_SPACE=" "
export RE_TAB="\t"
export RE_WHITESPACE="\s"
export POSIX_UPPER="[:upper:]"
export POSIX_LOWER="[:lower:]"
export POSIX_ALPHA="[:alpha:]"
export POSIX_DIGIT="[:digit:]"
export POSIX_ALNUM="[:alnum:]"
export POSIX_PUNCT="[:punct:]"
export POSIX_SPACE="[:space:]"
export POSIX_WORD="[:word:]"

## string "objects"
@str() {
  unsetopt warn_create_global
  local name="${1}" && shift
  local value="\"${@}\""
  declare -rg $name=$value
  functions[$name]="echo ${value}"  
  eval "
function "$name" { echo "${value}"; }
alias -g $name="$name"
function $name.upper() { echo ${value} | upper ; }
function $name.lower() { echo ${value} | lower ; }
function $name.trim() { echo ${value} | trim ; }
function $name.trim.left() { echo ${value} | trim.left ; }
function $name.trim.right() { echo ${value} | trim.right ; }
function $name.len() { echo ${value} | len ; }
"
  _n() {
    val="${1}"
    funtion "$name".squeeze() { 
      local opt=$1; echo ${val} | squeeze "$val" "$opt"
    }
    funtion "$name".detox() { 
      local opt=$1; echo ${val} | detox "$val" "$opt"
    }
    funtion "$name".camel() { 
      local opt=$1; echo ${val} | trim | camel "$val" "$opt"
    }
    funtion "$name".snake() { 
      local opt=$1; echo ${val} | trim | snake "$val" "$opt"
    }
    funtion "$name".extract() { 
      local opt=$1; 
      local delim="$2"
      echo ${val//\"/} | awk -F"$delim" '{print $'$opt'}' 
    }
    funtion "$name".replace() { 
      local opt=$1; 
      local repl="$2"
      echo ${val//\"/} | replace "$opt" "$repl"
    }
  }
  _n "${value}"
}
functions["@str"]="@str"  
alias -g @str="@str"
###
# or() { (($? == 0)) || "$@"; }
# and() { (($? == 0)) && "$@"; }
## a number "object"
@num() {
  unsetopt warn_create_global
  local name="${1}"
  local value=${2}
  declare -rg $name=$value
  functions[$name]="echo ${value}"  
  eval "
function $name { echo ${value}; }
alias -g $name="$name"
"
  function _n() {
    val="$1"
    function "$name".add() { local opt=$1; add "$val" "$opt" }
    function "$name".sub() { local opt=$1; sub "$val" "$opt" }
    function "$name".mul() { local opt=$1; mul "$val" "$opt" }
    function "$name".div() { local opt=$1; div "$val" "$opt" }
    function "$name".pow() { local opt=$1; pow "$val" "$opt" }
    function "$name".mod() { local opt=$1; mod "$val" "$opt" }
    function "$name".eq() { local opt=$1; eq "$val" "$opt" }
    function "$name".ne() { local opt=$1; ne "$val" "$opt" }
    function "$name".gt() { local opt=$1; gt "$val" "$opt" }
    function "$name".lt() { local opt=$1; lt "$val" "$opt" }
    function "$name".ge() { local opt=$1; ge "$val" "$opt" }
    function "$name".le() { local opt=$1; le "$val" "$opt" }
    function "$name".incr() { incr $val }
    function "$name".decr() { decr $val }
    function "$name".sum() { local args="$@"; sum "$args" }
  }
  _n "$value"
}
functions["@num"]="@num"  
alias -g @num="@num"

###
# use namespace to load vars and functions into an environment
# eg:
# block example {
#   let value 12;
#   func show_value print $value;
#   }
# }
alias block='function'

