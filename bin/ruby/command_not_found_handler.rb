#!/usr/local/opt/ruby/bin/ruby --disable=gems

require 'json'
strarg = ARGF.read
pipearg = strarg.split('')
cmd_arg = strarg.split(' ')
firstchar = pipearg[0]
if firstchar == '@'
  pipearg.shift()
  puts pipearg.join().strip
else
  function_file = File.expand_path('~/zsh-config/functions.json')
  config_functions = JSON.parse(File.read(function_file))['functions']
  config_functions.sort.each do |name, body|
    if name == cmd_arg[0]
      puts "[zsh] function '#{name}' is not loaded. run 'loadf #{name}'"
      return
    end
  end
  puts "[zsh] command not found: #{strarg}"
end
