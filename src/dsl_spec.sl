# NOTE: this is a good idea HOWEVER...
# --> I can use lua / teal (https://pdesaulniers.github.io/tl/) with 
#     the luash module (https://github.com/zserge/luash) to do most of this

# a spec for a(nother) programming language, by example

# very strict replacement for shell scripts
# inspired by zsh, tcl, ruby, functional languages
# this language is an attempt to bring strong types, 
#    better data structures, and named function arguments 
#    to scripts with access to shell / gnu tools but 
#    without the limitations of actual shell scripting
# this idea started with dsl.zsh
#    github.com/unforswearing/zsh-config/blob/main/bin/dsl.zsh

# features:
# eager / strict language
# strict / static types
# text does not need to be quoted but can be where appropriate
# spaces are ignored
# it is impossible to overwrite or delete files
# no import statements but shell scripts can be sourced using !~
# things like math, dates, and string operations use shell commands via !~
# note: math, dates, strings, etc may be adde to this language later on

# ==================== #
# language             #
# ==================== #

#  operator   name              use in language
#  --------   --------------    -------------------------------------
#     ::      double colon      get class of variable
#     #       pound sign        single line comment
#     $       dollar sign       variable reference 
#     >       right arrow       write to file
#     *>      star arrow        append to file
#     <       left arrow        read from file / user input
#     @       at sign           call function
#     []      square brackets   function arguments
#     ?       question mark     if / test comparison
#     %       percent sign      then clause for if blocks
#     +       plus sign         list parameter name reference
#     .       period            list recursion, equivalent to "foreach"
#     ..      double period     end list recursion, equivalent to "done"
#     !~      exclaim tilde     run shell commands
#     !!      double exclaim    exit script

# -------- #
# types
# -------- #

# all types start with :
# any user created var starting with : will throw a type error


:bool
:fun
:list
:num
:str

:file
:path

:true
:false
:none

:ref
:err

# the :true and :false type return their values
# use these to create true or false variable placeholders
# the variable named `completed` will have the value :true

:true completed

# the :ref type is used for loop variables, file contents, etc
#    anywhere the type is already set or is unknown

:ref $example

# the :err type is used to throw errors in scripts
# exit a script by using the double exclaim !!

$example ? 
  :none % :err 'variable example has no value' !!
       %% :str 'value is $example::str'

# type conversion --------- #

# use double colon to convert to another type
# any user created var starting with :: with throw a type error
# only applies to :str, :bool, and :num
# also applies to :ref if value can be converted to :str, :bool, or :num
# however multiline strings can be converted to pseudo indexed lists
#   where each line is a new numbered parameter in the converted variable
# :num to :bool - any value above or below 0 is :true, 0 is :false
#                 eg. -10 is :true, 55 is :true, 0 is :false
# :str to :bool - any value is :true, empty string is :false
# an error will occur when trying to convert :list and :fun into other values

'the value is $total::str'

# get variable class ------------- #

# to find the class of a variable, use ::

:str firstname jane
:: $jane 

# -------- #
# comments #
# -------- #

# comments begin with hash / pound sign
# comments occupy the full line
#   an error will be thrown if code is followed by comment
# this is another comment


# --------------- #
# typed variables #
# --------------- #

# variables can be created using their type name
# vars, functions, and lists are all immutable
# vars must have a value upon initialization, otherwise an error will be thrown
# the equals sign is not used for assignment anywhere in this language

:num total 3

# variables are used by prepending an $ symbol
# because both shell and this lang use $ all vars
#   in these scripts are available in the underlying shell env
# use :ref to get the value of a variable

:ref $total

# convert the $total var to a string
# quoting a non-string variable will throw an error

:str 'your total is $total::str'


# ------------------------------ #
# reading / writing / user input #
# ------------------------------ #

# the right arrow > can be used to write to files
# the command will throw an error if the file exists

:ref $total > :file 'total.txt'

# append to a file using the star arrow *>

:num 15 *> :file 'total.txt'

# similarly, read from a file using `< :file name.txt`

:num savedtotal < :file 'total.txt'

# the left arrow < can also be used to get user input

:str input < 


# --------- #
# functions #
# --------- #

# use the `:fun` type to create functions
# functions without args should use [:none] as argument placeholder
# the return value is the result of the last command
# in `:fun hello` the return value is 'hello friend'

:fun hello [:none] :str 'hello friend'

# named arguments can be wrapped in square brackets
# the hello function below returns the string "hi there" and value of $name var

:fun hello [:str name] :str 'hi there $name'

# functions are called using the @ symbol

@hello 'bob'


# ------------------------ #
# branching / control flow #
# ------------------------ #

# the ? retrieves the value of preceding variable
#    and compares it with the value or type that follows
# the % is executed when the condition is true
# the %% is used as a fall through option if there are no other matches

:str name 'bob'
$name ? bob    % :str '$name is one of my friends'
      ? steve  % :str '$name is another friend'
              %% :str 'no matches for $name'

# -------- #
# lists    #
# -------- #

# the list is the only data structure and works like a dictionary
# lists and list values are immutable
# lists can not have a value without a parameter name
# lists cannot be nested
# all parameter names must have a value
# lists cannot be dynamically created (eg. in a loop)
# parameter names are denoted with a plus sign
# parameter names can have no spaces
# parameter names can be strings or numbers
# parameters must have types
# parameter values can have spaces

:list userinfo
  +name :str 'bob'
  +age  :num 35
  +city :str 'denver'

# or create a list on a single line (less readable for longer lists)

:list userdict +name :str 'bob' +age :num 35 +city :str 'denver'

# use :ref to get the full contents of the list

:ref $userdict

# retrieve specific items from a list using its param name prepended with +

:ref $userdict +city

# lists are unordered and do not have a index to reference
# in order to use pseudo indexing create a list with numbers as param names
# note: use any number to start the pseudo index
# the example below uses 0-based pseudo indexing

:list friends
  +0 :str 'bob'
  +1 :str 'steve'
  +2 :str 'mary'

# now retrieve items from the dict using the pseudo index

:str bestfriend :ref $friends +2


# ------------------ #
# looping over lists #
# ------------------ #

# loop over the list using .
# end the loop using the double period ..
# since var `item` is referencing a list parameter name
#   use the + to initialize this variable
#   `item` can then be used as a regular variable prepended with $

:ref $userlist . [+item] :ref $item ..

# include an iterator
# iterator must always follow the parameter var name

:ref $userlist . [+item :num i]
  :str itemindex '$item::str is number $i::str'
  :ref currentcontents $contents+$i

  :ref $currentcontents
  :str $itemindex
..


# --------------------------- #
# using the shell environment #
# --------------------------- #

# interaction with the system can be done using !~
# shell commands can start anywhere on the line but must run to the end
# non-shell code after a shell command will throw an error
# examples:

# save the current date to a variable

:str now !~ gdate '+%Y-%m-%dT%H:%M'

# get the value of an environment variable

:str editor !~ print $EDITOR

# perform arbitrary shell actions

!~ cd /usr/local/bin
:str command 'echo "location is $(pwd)"'
!~ eval $command

# source a zsh script for use in !~ commands
# dsl.zsh contains the command 'lower'

!~ source dsl.zsh

:fun tolower [:str text] 
  :str !~ print $text | lower

:str lowercase @tolower 'UPPER CASE TEXT'
:ref $lowercase










