# #################################################
# this exists seperately / alongside stdlib.zsh
# neither file relies on the other and can be used independently
# -----------------------------------------
# pseduo types: a way to create types in zsh, retaining zsh-isms
# - everything is text unless casted otherwise
# - all casted items have the list as a primary type
# - this means strings are lists of chars, floats are lists of numbers
#   and functions are lists of commands
# - all of these items can be treated like a list where necessary
# -----------------------------------------
# (pseudo types - type signatures)
# (type signatures are used to declare types, not check)
# type       in zsh
# ----------------------------
# nil - cat /dev/null
# bool  - true false
# number - never quoted. /[0-9]{1}/
# char - always quoted. /[aA-zZ]|[0-9]|\s|\t|[:punct:]{1}/
# list - typeset -a name=("this" "is" "a" "list")
# str - strings are lists of chars
#      | eg: string name="robert smith"
# float - floats are lists of one or more numbers, using half precision 
# fun - functions are lists of commands
#      | the 'fun' type creates the signature for a function
#      | eg: fun getage (str $1) -> num
#      |     getage() { `$name match "robert smith"` && print $age; }
# note: ---
#      | str and num output is an immutable function that returns the value
#      | output functions all have a param called 'type'
#      | eg. str hello="world"; hello type => str
# --------------------------------------------------
# see also:
# - value-level programming: https://en.wikipedia.org/wiki/Value-level_programming
# - static typing: https://en.wikipedia.org/wiki/Type_system#Static_type_checking
# - nominal type system: https://en.wikipedia.org/wiki/Nominal_type_system
# - the abstract type: https://en.wikipedia.org/wiki/Abstract_type
# - types produce immutable values
# - no type constructor
# - no type coersion
# - no aliases

# #################################################
# @todo revise how these work (numbers should use `float`, etc)
# @todo develop an internal way to track references to the types
# @todo once internal type method is derived, create funcs to get and convert types
# @todo use a python with the `typing` and `mypy` modules
# 
# pseudo types were pulled from stdlib. 
# create pseudo types: nil, num, const, atom
#
# instead of Lua for types, use Python. Including:
#
# - typing: https://docs.python.org/3/library/typing.html
# - mypy: https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html#cheat-sheet-py3
#
# with these I do not have to use some weird / outdated / incompatible typed lua dialect like teal (cool, but requires type files and examples are non-existent), or luau (incompatible with MacOS < 10.12), or Terra (systems programming library that calls itself a language built onto Lua), and etc. 
# #################################################
#
# ------ use zsh-based variable declaration ------
# (these do not set a type, only modify access for vars)
# set        init variables outside of functions: `set name`
# local      init variables inside of functions: `local name`
# readonly   constants: `readonly name="mike"`
# export     globals: `export fullname="$name thomas"`
# -------------------------------------------------
#
# note: the method of checking types (using `isstr` for example) 
# may not be necessary since any item using a type signature 
# will have the type added to the resulting function as a parameter. 
# for example `nil result; result type` => prints 'nil'
#
# #################################################
# 
# use the functions below to define what each type is
# for later comparison. not all functions will be type signatures
# ------------------------