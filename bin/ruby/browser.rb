#!/usr/local/opt/ruby/bin/ruby --disable=gems

# browser.rb: cat html to preview in Chrome.
# eg. `cat file.md | cmark | browser.rb`
#
# This command used to be installed on Homebrew but
# was removed at some point. Using ruby to create my own.

require_relative "colors"

# `ARGF.read` turns `ARGV` into a text stream for accepting pipes
# using `STDIN.tty?` to determine if text has been piped to this script
#   -> see: https://stackoverflow.com/a/25358600
case STDIN.tty?
  when true
    puts "No input to browser.rb".red
    exit 1
end

input = ARGF.read

tmpfile = "/tmp/browser.rb.tmp#{rand(10**5)}.html"
File.write(tmpfile, input)

`open #{tmpfile}`
