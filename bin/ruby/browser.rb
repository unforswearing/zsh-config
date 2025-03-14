#!/usr/local/opt/ruby/bin/ruby --disable=gems

# browser.rb: cat html to preview in Chrome.
# eg. `cat file.md | cmark | browser.rb`
#
# This command used to be installed on Homebrew but
# was removed at some point. Using ruby to create my own.

require_relative "colors"

input = ARGF.read
unless defined?(input)
  puts "No input to browser.rb".red
  exit 1
end

tmpfile = "/tmp/browser.rb.tmp#{rand(10**5)}.html"
File.write(tmpfile, input)

`open #{tmpfile}`
