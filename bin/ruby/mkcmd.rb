#!/usr/local/opt/ruby/bin/ruby --disable=gems
# command builder / executor for ruby scripts and the shell
# this script helps build complex, multi-pipe **single line**
# commands for the shell (aka "oneliners").

# base command, optional path
# error if not found

# options, array

# optional pipe command `pipe(obj)`
# pipe accepts an object suchas
#
# ```
# pipe_content = {
#   "command" => "command_name"
#   "options" => [ "--option value", "--option=2" ]
# }
# ```
#
# a fully composed, multi-pipe command (essentially an AST):
#
# ```
# build_obj = {
#   # command name, arguments split on space
#   "begin" => [
#     "/usr/local/bin/fd", "-t", "d", "-d", "1",
#     "--exclude=dev", "--exclude=docs"
#   ],
#   # encountering the pipe char creates a "pipe" in the obj
#   "pipe" => {
#     # pipes within commands are structured the same as outside cmds
#     # each line of commands in the loop is an array
#     # to disambiguate commands, `array[0]` == command name
#     # (eg. prevent conflicts for multiple executions of the same cmd name)
#     "while read directory; do" => [
#       [ "cd", "$directory", "||", "exit 1"],
#       [ "/usr/local/bin/rg", "--files", "--glob '!scripts*'" ],
#       # pipes can contain sub-pipes, like the one below
#       [ "pipe" => {
#         "tree" => [
#            "--fromfile", "-P '*.pdf'", "-H ./", ">| index.html"
#          ]
#       }],
#       [ "cd", ".." ]
#     ],
#   },
#   "end" => [ "echo", "\"script complete\""]
# }
# ```
#
