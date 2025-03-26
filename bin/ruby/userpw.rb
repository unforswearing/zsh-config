#!/usr/bin/ruby
require 'io/console'

# The prompt is optional
password = IO::console.getpass "Enter Password: "
puts "Your password was #{password.length} characters long."