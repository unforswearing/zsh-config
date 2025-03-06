#!/usr/local/opt/ruby/bin/ruby --disable=gems

# `shenv.rb` is a way to source shell functions from `functions.json`
# into ruby shell commands. Source this script in a ruby shell script
# and use `shenv <function-name>` in a ruby shell command.
# eg.
# ```
# require 'shenv.rb'
# shenv_source = load_shenv()
# `source #{shenv_source}; loadf filebak; filebak test.txt`
#


require File.expand_path("~/zsh-config/bin/ruby/functions.rb")

function_loadf = <<-FBODY

FBODY
